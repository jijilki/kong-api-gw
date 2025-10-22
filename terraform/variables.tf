variable "instance_type" {
  type = string                     # The type of the variable, in this case a string
  default = "t2.micro"                 # Default value for the variable
  description = "The type of EC2 instance" # Description of what this variable represents
}

variable "region" {
  description = "AWS region"
  type = string
  default = "ap-south-1"
}

variable "ami_owner" {
  description = "AMI Owner"
  type = string
  default = "099720109477"
}
variable "ubuntu_version" {
  description = "Ubuntu version"
  type = string
  default = "22.04"
}

variable "key_pair_name" {
  description = "EC2 key pair name for SSH access"
  type = string
}