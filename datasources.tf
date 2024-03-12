# data "aws_ami" "server_ami" {
#   most_recent = true
#   owners      = ["137112412989"]

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-kernel-5.10-hvm-2.0.20240223.0-x86_64-gp2"]
#   }
# }

data "aws_ami" "server_ami" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_s3_bucket" "alb_logs" {
  bucket = "raj-alb-logs-2"
}