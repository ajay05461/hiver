################OUTPUT Section ######################

#output "nic_details" {
#  description = "NIC Details"
#  value       = { for k, v in aws_network_interface.nic : v.private_ip => v.id }
#}
#
output "subnetdetails" {
  description = "subnet details"
  value       = local.regiontosubnetmap
}

#output "networkmap" {
#  description = "network map"
#  value       = local.iptoregionmap
#}
#
#output "webinstanceid" {
#	description = "Instance ids of web"
#	value =  local.webinstanceid
#}

output "applbpublicdns" {
  description = "App Loadbalancer fqdn"
  value       = aws_lb.appelb.dns_name
}

output "weblbpublicdns" {
  description = "Web Loadbalancer fqdn"
  value       = aws_lb.webelb.dns_name
}

output "websubnets" {
  description = "Web subnets"
  value       = local.websubnets
}
