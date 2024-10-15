import boto3
from botocore.exceptions import ClientError

def revoke_security_group_rules(ec2, sg_id):
    """Revoke all ingress and egress rules referencing other security groups."""
    try:
        # Fetch current rules
        sg_info = ec2.describe_security_groups(GroupIds=[sg_id])
        ip_permissions = sg_info['SecurityGroups'][0].get('IpPermissions', [])
        ip_permissions_egress = sg_info['SecurityGroups'][0].get('IpPermissionsEgress', [])
        
        # Revoke inbound rules that reference other security groups
        for permission in ip_permissions:
            if 'UserIdGroupPairs' in permission:
                for group_pair in permission['UserIdGroupPairs']:
                    ec2.revoke_security_group_ingress(GroupId=sg_id, IpPermissions=[permission])
        
        # Revoke outbound rules that reference other security groups
        for permission in ip_permissions_egress:
            if 'UserIdGroupPairs' in permission:
                for group_pair in permission['UserIdGroupPairs']:
                    ec2.revoke_security_group_egress(GroupId=sg_id, IpPermissions=[permission])
        
    except ClientError as e:
        print(f"Error revoking rules for security group {sg_id}: {e}")

def delete_security_groups_except_default():
    ec2 = boto3.client('ec2')
    
    try:
        # Describe all security groups
        response = ec2.describe_security_groups()
        security_groups = response['SecurityGroups']

        # Filter out the default security group
        default_sg_id = None
        for sg in security_groups:
            if sg['GroupName'] == 'default':
                default_sg_id = sg['GroupId']
                break

        if not default_sg_id:
            print("No default security group found.")
            return

        # Iterate through the security groups and delete non-default ones
        for sg in security_groups:
            sg_id = sg['GroupId']

            if sg_id != default_sg_id:
                print(f"Processing Security Group: {sg_id}")

                # First revoke any rules referencing other security groups
                revoke_security_group_rules(ec2, sg_id)

                # Now delete the security group if not in use
                try:
                    network_interfaces = ec2.describe_network_interfaces(Filters=[{'Name': 'group-id', 'Values': [sg_id]}])['NetworkInterfaces']
                    if not network_interfaces:
                        ec2.delete_security_group(GroupId=sg_id)
                        print(f"Deleted Security Group: {sg_id}")
                    else:
                        print(f"Security Group {sg_id} cannot be deleted due to existing associations with network interfaces.")

                except ClientError as e:
                    print(f"Error deleting security group {sg_id}: {e}")

    except ClientError as e:
        print(f"Error describing security groups: {e}")

if __name__ == "__main__":
    delete_security_groups_except_default()
