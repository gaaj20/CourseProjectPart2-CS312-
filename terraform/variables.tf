variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type (t3.medium recommended for Minecraft)"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of the AWS key pair to create"
  type        = string
  default     = "minecraft-key"
}

variable "public_key_path" {
  description = "Path to your SSH public key file"
  type        = string
  default     = "~/.ssh/minecraft_key.pub"
}

variable "minecraft_version" {
  description = "Minecraft server version to deploy"
  type        = string
  default     = "1.21.1"
}
