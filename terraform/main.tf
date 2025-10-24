resource "aws_security_group" "kong_sg" {
  name        = "kong-sg"
  description = "Allow kong ports"
  vpc_id      = null // #use default vpc
  ingress {
    description = "Kong proxy (8000)"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Kong admin (8001)"
    from_port   = 8001
    to_port     = 8001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


data "aws_ami" "ubuntu" {
  //this is data not a resource
  most_recent = true
  owners = [var.ami_owner] #Canonical
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-${var.ubuntu_version}-amd64-server-*"]
  }
}


resource "aws_instance" "kong" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.kong_sg.id]
  user_data = file("${path.module}/../kong/ec2-userdata.sh")
  iam_instance_profile   = aws_iam_instance_profile.kong_instance_profile.name

  tags = {
    Name = "kong-api-gw"
  }
}

# IAM Role for EC2 to send logs to CloudWatch
resource "aws_iam_role" "kong_ec2_role" {
  name = "kong-ec2-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Effect = "Allow"
      Sid    = ""
    }]
  })
}

# Attach the AWS managed CloudWatch agent policy
resource "aws_iam_role_policy_attachment" "cw_agent_attach" {
  role       = aws_iam_role.kong_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create instance profile to attach the IAM role to EC2
resource "aws_iam_instance_profile" "kong_instance_profile" {
  name = "kong-instance-profile"
  role = aws_iam_role.kong_ec2_role.name
}


resource "aws_s3_bucket" "neo_code_artifacts" {
  bucket        = "neo-code-artifacts-bucket"
  acl           = "private"
  force_destroy = false

  tags = {
    Name = "neo-code-artifacts-bucket"
    Env  = "prod"
  }
}

resource "aws_s3_bucket_public_access_block" "neo_code_artifacts_block" {
  bucket = aws_s3_bucket.neo_code_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_policy" "kong_ec2_s3_access" {
  name        = "kong-ec2-s3-access"
  description = "Allow EC2 instances in kong role to access neo-code-artifacts-bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.neo_code_artifacts.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.neo_code_artifacts.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy_to_kong_role" {
  role       = aws_iam_role.kong_ec2_role.name
  policy_arn = aws_iam_policy.kong_ec2_s3_access.arn
}
