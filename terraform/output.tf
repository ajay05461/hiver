output "nlbaddress"{
        description = "Network load balancer dns name"
        value = aws_lb.nlb.dns_name
}
