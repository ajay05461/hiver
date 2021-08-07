import boto3
import argparse

def createEc2Client():
    return boto3.client('ec2')


def getDefaultVpcId(ec2client):
    for vpc in ec2client.describe_vpcs().get('Vpcs'):
        if vpc.get('IsDefault'):
            return vpc.get('VpcId')


def getEc2Instances(ec2client, vpc_id, instance_type):
    instanceDict = dict()
    response = ec2client.describe_instances(
        Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}, {'Name': 'instance-type', 'Values': [instance_type]}])
    if len(response.get('Reservations')) > 0:
        for reservation in response.get('Reservations'):
            for instance in reservation.get('Instances'):
                instanceId = instance.get('InstanceId')
                for tag in instance.get('Tags'):
                    if tag.get('Key') == 'Name':
                        instanceName = tag.get('Value')
                instanceDict[instanceId] = instanceName
    print("{:<30} {:<30}".format('Name Tag', 'Instance ID'))
    for id, name in instanceDict.items():
        print("{:<30} {:<30}".format(name, id))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", default="m5.large",help="ec2 instance-type to look for")
    args = parser.parse_args()
    ec2client = createEc2Client()
    default_vpc_id = getDefaultVpcId(ec2client)
    getEc2Instances(ec2client, default_vpc_id, args.i)
