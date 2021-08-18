output "vpcid1"{
        description = "VPC ID of vpc-1"
        value = module.vpc1.vpc_id
}

output "vpcid2"{
        description = "VPC ID of vpc-2"
        value = module.vpc2.vpc_id
}

output "amiid"{
	description = "Ami id"
	value = data.aws_ami.amazon-linux-2.id
}

output "vpc1instanceip"{
	description =  "Instance ips of ec2 instances spawned in vpc-1"
	value = aws_instance.server1.*.public_ip
}

output "vpc2instanceip"{
        description =  "Instance ips of ec2 instances spawned in vpc-2"
        value = aws_instance.server2.*.public_ip
}
