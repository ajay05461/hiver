# hiver
Steps to run for terraform task:
1.	Install the aws cli and configure
2.	Run ‘aws ec2 create-key-pair --key-name MyKeyPair --query 'KeyMaterial' --output text > MyKeyPair.pem’
3.	Install terraform 
4.	Run ‘terraform init’
5.	Run ‘terraform validate’
6.	Run ‘terraform apply –auto-approve’
7.	After the execution of terraform apply, it prints the output of network load balancer dns name

Steps to run for getting the ec2 instance details of a certain type:
1.	Install boto3
2.	Run ‘python3 getEc2Details.py(to get m5.large instance details) or python3 getEc2Details.py -i t2.micro(to list t2.micro instances)’
