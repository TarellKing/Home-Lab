output "vpc_id" { value = module.network.vpc_id }
output "public_decoy_instance_id" { value = module.compute.decoy_instance_id }
output "public_decoy_public_ip" { value = module.compute.decoy_public_ip }
output "internal_instance_id" { value = module.compute.internal_instance_id }
output "audit_bucket_name" { value = module.logging.audit_bucket_name }
output "fake_data_bucket_name" { value = module.storage.fake_data_bucket_name }
