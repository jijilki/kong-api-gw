# output "instance_public_ip" {
#   value = ""                                          # The actual value to be outputted
#   description = "The public IP address of the EC2 instance" # Description of what this output represents
# }

output "kong_proxy_url" {
  description = "Public url for kong proxy"
  value = "http://${aws_instance.kong.public_ip}:8000"
}

output "kong_admin_url" {
  description = "Admin url for kong proxy"
  value = "http://${aws_instance.kong.public_ip}:8001"
}