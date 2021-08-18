#!/bin/bash
sudo yum install docker -y
sudo systemctl start docker
sudo docker pull benpiper/r53-ec2-web
