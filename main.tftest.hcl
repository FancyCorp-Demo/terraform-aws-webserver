
# Basic auto-generated tests

variables {
  packer_bucket_name = "webserver"
  packer_channel     = "production"
  instance_type      = "t3.micro"
  vpc_name           = "strawbtest"
  route53_zone       = "lucy-davinhart.sbx.hashidemos.io"
}

run "variables_validation" {
  // This doesn't really do much right now...
  // but is a good placeholder for if we add more variable validation in future

  command = plan

  assert {
    condition     = var.packer_bucket_name == "webserver"
    error_message = "incorrect value for packer_bucket_name"
  }

  assert {
    condition     = var.packer_channel == "production"
    error_message = "incorrect value for packer_channel"
  }

  assert {
    condition     = var.instance_type == "t3.micro"
    error_message = "incorrect value for instance_type"
  }

  assert {
    condition     = var.vpc_name == "strawbtest"
    error_message = "incorrect value for vpc_name"
  }

  assert {
    condition     = var.route53_zone == "lucy-davinhart.sbx.hashidemos.io"
    error_message = "incorrect value for route53_zone"
  }
}


run "outputs_validation" {
  assert {
    condition     = output.ec2_connect_url != ""
    error_message = "ec2_connect_url should not be empty"
  }

  assert {
    condition     = output.web_server_ip != ""
    error_message = "web_server_ip should not be empty"
  }

  assert {
    condition     = output.web_server_url != ""
    error_message = "web_server_url should not be empty"
  }

  // TODO: Assert we get a 200 response
}

