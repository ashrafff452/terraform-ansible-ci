output "amazon_linux_public_ip" {
  value = aws_instance.amazon_linux.public_ip
}

output "amazon_linux_private_ip" {
  value = aws_instance.amazon_linux.private_ip
}

output "ubuntu_public_ip" {
  value = aws_instance.ubuntu.public_ip
}

output "ubuntu_private_ip" {
  value = aws_instance.ubuntu.private_ip
}