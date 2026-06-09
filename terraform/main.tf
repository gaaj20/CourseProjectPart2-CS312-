terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- Data Sources ---

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

# --- Security Group ---

resource "aws_security_group" "minecraft" {
  name        = "minecraft-sg"
  description = "Security group for Minecraft server"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Minecraft game port"
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH (for Ansible provisioning only)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "minecraft-sg"
    Project = "minecraft-server"
  }
}

# --- Key Pair ---

resource "aws_key_pair" "minecraft" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)

  tags = {
    Project = "minecraft-server"
  }
}

# --- EC2 Instance ---

resource "aws_instance" "minecraft" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.minecraft.key_name
  vpc_security_group_ids = [aws_security_group.minecraft.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name    = "minecraft-server"
    Project = "minecraft-server"
  }
}

# --- Elastic IP ---

resource "aws_eip" "minecraft" {
  instance = aws_instance.minecraft.id
  domain   = "vpc"

  tags = {
    Name    = "minecraft-eip"
    Project = "minecraft-server"
  }
}
