
output "ec2_connect_url" {
  value = "https://${data.aws_region.current.name}.console.aws.amazon.com/ec2/v2/connect/ubuntu/${aws_instance.web.id}"
}

output "web_server_url" {
  value = local.webserver_url
}

output "response" {
  value = terracurl_request.test.response
}
