# Define variables
variable "aws_region" {
  default = "eu-west-1"
}

variable "ec2_instance_type" {
  default = "t2.micro"
}

variable "s3_bucket_name" {
  default = "terra-bucket-sftp"
}
data "aws_key_pair" "existing_key_pair" {
  key_name = "ppr"
}

# Provision an EC2 instance with Ubuntu AMI
resource "aws_instance" "ec2_instance" {
  ami           = "ami-0c94855ba95c71c99"  # Ubuntu 20.04 LTS
  instance_type = var.ec2_instance_type
  key_name = data.aws_key_pair.existing_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.ec2_instance_security_group.id]
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y openssh-server
              mkdir /var/run/sshd
              echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
              service ssh restart

              # Create the desired SFTP mount location
              mkdir /mnt/s3

              # Install s3fs
              apt-get install -y s3fs

              # Configure AWS credentials for s3fs
              echo 'AKIAR7K6DLN6YNMJFWNC:u9MKK19jZ7Gem5Q92Ovdr8PgsbgtrrrLrEjHd/fh' > /etc/passwd-s3fs
              chmod 600 /etc/passwd-s3fs

              # Mount the S3 bucket to the desired mount location
              echo 'terra-bucket-sftp:/ /mnt/s3 fuse.s3fs _netdev,allow_other 0 0' >> /etc/fstab
              mount -a

              # Configure SFTP access
              echo 'Match User SftpUser' >> /etc/ssh/sshd_config
              echo '    ForceCommand internal-sftp' >> /etc/ssh/sshd_config
              echo '    PasswordAuthentication yes' >> /etc/ssh/sshd_config
              echo '    ChrootDirectory /mnt/s3' >> /etc/ssh/sshd_config
              echo '    PermitTunnel no' >> /etc/ssh/sshd_config
              echo '    AllowAgentForwarding no' >> /etc/ssh/sshd_config
              echo '    AllowTcpForwarding no' >> /etc/ssh/sshd_config
              echo '    X11Forwarding no' >> /etc/ssh/sshd_config

              service ssh restart
              EOF


  tags = {
    Name = "EC2 Instance"
  }
}

# Create a security group for the EC2 instance
resource "aws_security_group" "ec2_instance_security_group" {
  name        = "EC2InstanceSecurityGroup"
  description = "Security group for EC2 instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an IAM role for the EC2 instance with full S3 access
resource "aws_iam_role" "ec2_instance_role" {
  name = "EC2InstanceRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach a policy to the IAM role for the EC2 instance with full S3 access
resource "aws_iam_role_policy_attachment" "s3_access_policy_attachment" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Create an S3 bucket
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.s3_bucket_name
  acl    = "private"

  tags = {
    Name = "S3 Bucket"
  }
}

# Create an IAM user for SFTP access with read/write/execute permissions
resource "aws_iam_user" "sftp_user" {
  name = "SftpUser"
}

resource "aws_iam_access_key" "sftp_user_access_key" {
  user = aws_iam_user.sftp_user.name
}

resource "aws_iam_policy" "s3_upload_policy" {
  name        = "S3UploadPolicy"
  description = "Policy allowing S3 upload for SFTP user"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${var.s3_bucket_name}",
        "arn:aws:s3:::${var.s3_bucket_name}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "s3_upload_policy_attachment" {
  name       = "S3UploadPolicyAttachment"
  policy_arn = aws_iam_policy.s3_upload_policy.arn
  users      = [aws_iam_user.sftp_user.name]
}

output "ec2_instance_public_ip" {
  value = aws_instance.ec2_instance.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.s3_bucket.bucket
}

output "sftp_user_access_key" {
  value     = aws_iam_access_key.sftp_user_access_key.secret
  sensitive = true
}

output "sftp_user_secret_key" {
  value     = aws_iam_access_key.sftp_user_access_key.secret
  sensitive = true
}
