variable "ingressrules" {
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
  }))

  default = [
    {
      description = "Allow http traffic"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
    },
    {
      description = "Allow https traffic"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
    }
  ]
}

variable "numofec2instance" {
  description = "Number of ec2 instances to be spawned"
  type        = number
  default     = 2
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
