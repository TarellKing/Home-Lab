output "decoy_instance_id" { value = aws_instance.decoy.id }
output "decoy_public_ip" { value = aws_instance.decoy.public_ip }
output "internal_instance_id" { value = try(aws_instance.internal[0].id, null) }
