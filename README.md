AWS EC2 Instance with SFTP Access:
This Terraform script provisions an EC2 instance in the specified AWS region with SFTP (Secure File Transfer Protocol) access, allowing users to securely upload and download files to and from an S3 bucket.
Prerequisites:
Before running this script, make sure you have the following:

AWS account credentials configured on your local machine.
Terraform installed on your local machine.
Usage:
Clone the repository containing this script.

Open a terminal and navigate to the cloned repository.

Run the following command to initialize Terraform:
"terraform init"
Modify the variables in the script if needed. The default values are already provided.

Run the following command to apply the Terraform configuration and provision the resources
"terraform apply"
After the provisioning is complete, the EC2 instance's public IP address, S3 bucket name, and SFTP user access keys will be displayed as outputs.

Accessing the EC2 Instance
To access the EC2 instance:

Use an SSH client to connect to the EC2 instance using the public IP address displayed in the output.
Provide the SFTP user's access keys (access key ID and secret access key) to establish an SFTP connection.
The SFTP user will be chrooted to the /mnt/s3 directory, which corresponds to the S3 bucket created during provisioning.
Clean Up
To clean up and delete all the created resources:

Run the following command to destroy the provisioned resources:

"terraform destroy"
When prompted, confirm the destruction by typing yes.

Note:
Make sure to handle the SFTP user's access keys securely as they grant access to the S3 bucket.
It is recommended to customize the IAM policies and security group rules to meet your specific security requirements.
