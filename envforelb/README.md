Terraform & ansible code can be used to bringup the infra as demoed in https://app.pluralsight.com/library/courses/aws-networking-deep-dive-elb/table-of-contents

On execution of the terraform scripts, the below mentioned infra gets created along with internet facing & internal loadbalancers 

![image](https://user-images.githubusercontent.com/17516750/130398702-600c0eb5-896d-4ca8-bff1-7da683793f5c.png)


Follow the below steps to bring up the infra

1. aws configure (Provide the access key & secured access key)
2. aws ec2 create-key-pair --key-name MyKeyPair --query 'KeyMaterial' --output text > MyKeyPair.pem
3. cd envforelb ; terraform apply --auto-approve
4. Copy the applbpublicdns value from terraform output (Required to use this value while running ansible-playbook)
5. cp MyKeyPair.pem ansible; cd ansible; chmod 600 MyKeyPair.pem
6. ansible-playbook -i aws_ec2.yaml site.yaml -u ec2-user --private-key MyKeyPair.pem --extra-vars "appserver=http://[applbpublicdns output from terraform]:8080" (Update the app loadbalancer dnsname and execute the command)

  
