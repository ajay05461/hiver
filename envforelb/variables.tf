variable "demo-vpc" {
  description = "cidr range for demo vpc"
  type        = string
  default     = "172.31.0.0/16"
}

variable "demo-subnets" {
  description = "subnets for demo vpc"
  type        = map(any)
  default = {
    web-1a = ["172.31.1.0/24", "us-east-1a"]
    web-1b = ["172.31.2.0/24", "us-east-1b"]
    app-1a = ["172.31.101.0/24", "us-east-1c"]
    app-1b = ["172.31.102.0/24", "us-east-1d"]
  }
}

variable "web-sg" {
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_block  = list(string)
  }))

  default = [
    {
      description = "Allow http traffic"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_block  = ["0.0.0.0/0"]
    },
    {
      description = "Allow https traffic"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_block  = ["0.0.0.0/0"]
    },
    {
      description = "Allow https traffic"
      from_port   = 81
      to_port     = 81
      protocol    = "tcp"
      #cidr_block  = ["172.31.0.0/16"]
      cidr_block  = ["0.0.0.0/0"]
    },
    {
      description = "Allow ssh traffic"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_block  = ["0.0.0.0/0"]
    },
    {
      description = "Allow http traffic"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      #cidr_block  = ["172.31.1.0/24", "172.31.2.0/24"]
      cidr_block  = ["0.0.0.0/0"]
    },
    {
      description = "Allow https traffic"
      from_port   = 8443
      to_port     = 8443
      protocol    = "tcp"
      #cidr_block  = ["172.31.1.0/24", "172.31.2.0/24"]
      cidr_block  = ["0.0.0.0/0"]
    },
    {
      description = "Allow http traffic"
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_block  = ["172.31.101.0/24", "172.31.102.0/24"]
      cidr_block  = ["0.0.0.0/0"]
    }
  ]
}


variable "instance_type" {
  description = "Type pf ec2 instance"
  type        = string
  default     = "t2.micro"
}

variable "keyname" {
  description = "name of the key to attach to ec2 instance"
  type        = string
  default     = "MyKeyPair"
}

variable "networkmap" {
  description = "network map"
  type        = map(any)
  default = {
    "app-1a" = ["172.31.101.21", "172.31.101.99"]
    "app-1b" = ["172.31.102.22", "172.31.102.23"]
    "web-1a" = ["172.31.1.21"]
    "web-1b" = ["172.31.2.22", "172.31.2.23"]
  }
}

variable "webinstanceipassign" {
  description = "Ec2 ip assignment"
  default = {
    "web1" : "172.31.1.21"
    "web2" : "172.31.2.22"
    "web3" : "172.31.2.23"
  }
}

variable "appinstanceipassign" {
  description = "Ec2 ip assignment"
  default = {
    "app1" : "172.31.101.21"
    "app2" : "172.31.102.22"
    "app3" : "172.31.102.23"
  }
}

variable "dbinstanceipassign" {
  description = "Ec2 ip assignment"
  default = {
    "db" : "172.31.101.99"
  }
}

