terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# As this is now a TF module, we can't assume eu-west-2
# So get AZs and region dynamically
data "aws_availability_zones" "available" {
  state = "available"
}
data "aws_region" "current" {}

# Create a VPC
# While we could define each of the required resources manually...
# no need to re-invent the wheel when a really good module exists already

module "vpc" {
  # https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest 
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.7.0"

  name = "strawbtest"
  cidr = "10.0.0.0/16"

  azs            = data.aws_availability_zones.available.names[*]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

# Find a suitable AMI to use for this purpose

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["self"]
}

# Allow us to easily connect to the EC2 instance with AWS EC2 Connect

data "aws_ip_ranges" "ec2_instance_connect" {
  regions  = [data.aws_region.current.name]
  services = ["ec2_instance_connect"]
}

resource "aws_security_group" "ec2_instance_connect" {
  name        = "ec2_instance_connect"
  description = "Allow EC2 Instance Connect to access this host"

  vpc_id = module.vpc.vpc_id

  ingress {
    from_port        = "22"
    to_port          = "22"
    protocol         = "tcp"
    cidr_blocks      = data.aws_ip_ranges.ec2_instance_connect.cidr_blocks
    ipv6_cidr_blocks = data.aws_ip_ranges.ec2_instance_connect.ipv6_cidr_blocks
  }

  tags = {
    CreateDate = data.aws_ip_ranges.ec2_instance_connect.create_date
    SyncToken  = data.aws_ip_ranges.ec2_instance_connect.sync_token
  }
}

# Allow inbound HTTP access on standard port
# In Production, you'd want to configure SSL etc.
# potentially run behind a load balancer of some kind.
# you know, usual production stuff.
#
# But for this demo, this works fine.
resource "aws_security_group" "inbound_http" {
  name        = "inbound_http"
  description = "Allow inbound HTTP access"

  vpc_id = module.vpc.vpc_id

  ingress {
    from_port        = "80"
    to_port          = "80"
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Now create the EC2 instance
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [
    aws_security_group.ec2_instance_connect.id,
    aws_security_group.inbound_http.id,
  ]

  subnet_id = module.vpc.public_subnets[0]

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<ENDUSERDATA
cat << EOT > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
    img {
        width: 35em;
    }
</style>
</head>
<body>
<img src="${local.image_url}" />
<h1>Welcome to nginx</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
EOT
ENDUSERDATA
}
