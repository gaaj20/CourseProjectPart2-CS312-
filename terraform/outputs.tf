output "instance_public_ip" {
  description = "Public IP address of the Minecraft server (Elastic IP)"
  value       = aws_eip.minecraft.public_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.minecraft.id
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.minecraft.id
}

output "nmap_command" {
  description = "Command to verify the Minecraft server is reachable"
  value       = "nmap -sV -Pn -p T:25565 ${aws_eip.minecraft.public_ip}"
}

output "ansible_inventory_entry" {
  description = "Host entry to add to your Ansible inventory"
  value       = "minecraft ansible_host=${aws_eip.minecraft.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/minecraft_key"
}
