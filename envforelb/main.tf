###########PROVIDER Section############
provider "aws" {
  region = "us-east-1"
}

########### LOCALS Section ###################
locals {
  regiontosubnetmap = { for k, v in aws_subnet.elbsubnets : k => v.id }
  iptoregionmap     = flatten([for k, v in var.networkmap : [for i in range(length(v)) : { v[i] = lookup(local.regiontosubnetmap, k) }]])
  iptosubnetmap     = { for k, v in aws_network_interface.nic : v.private_ip => v.subnet_id }
  iptonicmap        = { for k, v in aws_network_interface.nic : v.private_ip => v.id }
  webinstanceid     = [for k, v in aws_instance.web : v.id]
  appinstanceid     = [for k, v in aws_instance.app : v.id]
  subnets           = [for k, v in aws_subnet.elbsubnets : v.id]
  websubnets        = [for k, v in local.regiontosubnetmap : v if contains(["web-1a", "web-1b"], k)]
  appsubnets        = [for k, v in local.regiontosubnetmap : v if contains(["app-1a", "app-1b"], k)]
}

########## DATA Section ##############

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  #  filter {
  #    name   = "owner-alias"
  #    values = ["amazon"]
  #  }


  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*x86_64-ebs"]
  }
}


############## Resources ##################
resource "aws_vpc" "elbvpc" {
  cidr_block           = var.demo-vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "elb_demo_vpc"
  }
}

resource "aws_internet_gateway" "elbigw" {
  vpc_id = aws_vpc.elbvpc.id
  tags = {
    Name = "elb_demo_igw"
  }
}

resource "aws_subnet" "elbsubnets" {
  vpc_id                  = aws_vpc.elbvpc.id
  for_each                = var.demo-subnets
  map_public_ip_on_launch = true
  availability_zone       = element(each.value, 1)
  cidr_block              = element(each.value, 0)
  tags = {
    Name = each.key
  }
}

resource "aws_route_table" "demo-rt" {
  vpc_id = aws_vpc.elbvpc.id
  tags = {
    Name = "demo-routetable"
  }
}

resource "aws_route" "demo-route" {
  route_table_id         = aws_route_table.demo-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.elbigw.id
}

resource "aws_route_table_association" "demo-rt-association" {
  for_each       = aws_subnet.elbsubnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.demo-rt.id
}

resource "aws_security_group" "demo-web-sg" {
  name        = "web-sg"
  description = "Allow Web traffic"
  vpc_id      = aws_vpc.elbvpc.id
  dynamic "ingress" {
    for_each = var.web-sg
    content {
      description = ingress.value["description"]
      from_port   = ingress.value["from_port"]
      to_port     = ingress.value["to_port"]
      protocol    = ingress.value["protocol"]
      cidr_blocks = ingress.value["cidr_block"]
    }
  }
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "web-sg"
  }
}

resource "aws_network_interface" "nic" {
  count           = length(local.iptoregionmap)
  subnet_id       = values(element(local.iptoregionmap, count.index))[0]
  private_ips     = [keys(element(local.iptoregionmap, count.index))[0]]
  security_groups = [aws_security_group.demo-web-sg.id]
  tags = {
    Name = "nic-${count.index}"
  }
}


resource "aws_instance" "web" {
  for_each = var.webinstanceipassign
  ami      = data.aws_ami.amazon-linux-2.id
  network_interface {
    network_interface_id = lookup(local.iptonicmap, each.value)
    device_index         = 0
  }
  key_name      = var.keyname
  instance_type = var.instance_type
  tags = {
    Name            = each.key
    Applicationtype = "web"
  }
}

resource "aws_instance" "app" {
  for_each = var.appinstanceipassign
  ami      = data.aws_ami.amazon-linux-2.id
  network_interface {
    network_interface_id = lookup(local.iptonicmap, each.value)
    device_index         = 0
  }
  key_name      = var.keyname
  instance_type = var.instance_type
  tags = {
    Name            = each.key
    Applicationtype = "app"
  }
}

resource "aws_instance" "db" {
  for_each = var.dbinstanceipassign
  ami      = data.aws_ami.amazon-linux-2.id
  network_interface {
    network_interface_id = lookup(local.iptonicmap, each.value)
    device_index         = 0
  }
  key_name      = var.keyname
  instance_type = var.instance_type
  tags = {
    Name            = each.key
    Applicationtype = "db"
  }
}

resource "aws_lb_target_group" "webhttp" {
  name     = "web-http"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.elbvpc.id
  health_check {
    path              = "/"
    protocol          = "HTTP"
    interval          = 10
    healthy_threshold = 2
  }
  stickiness {
    cookie_duration = 60
    type            = "lb_cookie"
    enabled         = true
  }
}

resource "aws_lb_target_group" "imagehttp" {
  name     = "image-http"
  port     = 81
  protocol = "HTTP"
  vpc_id   = aws_vpc.elbvpc.id
  health_check {
    path              = "/image.php"
    protocol          = "HTTP"
    port              = 81
    interval          = 10
    healthy_threshold = 2
  }
}

resource "aws_lb_target_group" "apphttp" {
  name     = "app-http"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.elbvpc.id
  health_check {
    path              = "/appserverinfo.py"
    protocol          = "HTTP"
    port              = 8080
    interval          = 10
    healthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "webhttp" {
  count            = length(local.webinstanceid)
  target_group_arn = aws_lb_target_group.webhttp.arn
  target_id        = element(local.webinstanceid, count.index)
  port             = 80
}

resource "aws_lb_target_group_attachment" "imagehttp" {
  count            = length(local.webinstanceid)
  target_group_arn = aws_lb_target_group.imagehttp.arn
  target_id        = element(local.webinstanceid, count.index)
  port             = 81
}

resource "aws_lb_target_group_attachment" "apphttp" {
  count            = length(local.appinstanceid)
  target_group_arn = aws_lb_target_group.apphttp.arn
  target_id        = element(local.appinstanceid, count.index)
  port             = 8080
}

resource "aws_lb" "webelb" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.demo-web-sg.id]
  subnets            = local.websubnets

  enable_deletion_protection = false

  tags = {
    Loadbalancer = "Web"
    Name         = "web-lb"
  }
}

resource "aws_lb" "appelb" {
  name               = "app-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.demo-web-sg.id]
  subnets            = local.appsubnets

  enable_deletion_protection = false

  tags = {
    Loadbalancer = "application"
    Name         = "app-lb"
  }
}

resource "aws_lb_listener" "weblb_listener" {
  load_balancer_arn = aws_lb.webelb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.webhttp.arn
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "imagegen" {
  listener_arn = aws_lb_listener.weblb_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.imagehttp.arn
  }

  condition {
    path_pattern {
      values = ["/image.php"]
    }
  }
}

resource "aws_lb_listener" "applb_listener" {
  load_balancer_arn = aws_lb.appelb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.apphttp.arn
    type             = "forward"
  }
}
