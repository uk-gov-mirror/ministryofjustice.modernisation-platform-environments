# Development-only EC2 instance based on the ebsdb AMI, with only the root volume attached.
# This resource is created only when the workspace is the development environment.

resource "aws_instance" "ec2_oracle_ebs_dev_test" {
  count = local.is-development ? 1 : 0

  instance_type               = "t3.large"
  ami                         = local.application_data.accounts[local.environment].ebsdb_ami_id
  key_name                    = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_ebsdb.id]
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name

  cpu_options {
    core_count       = 2
    threads_per_core = 1
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 100
    encrypted   = true
    tags = merge(local.tags,
      {
        Name = "dev-test-root-block"
      }
    )
  }

  user_data_replace_on_change = false
  user_data = base64encode(<<EOF
#!/bin/bash
set -e

# Install AWS Systems Manager Agent
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Install AWS Mountpoint for Amazon S3
yum install -y fuse fuse-libs fuse-devel
wget https://s3.amazonaws.com/mountpoint-s3-public/latest/x86_64/mount-s3.rpm
yum install -y ./mount-s3.rpm
rm -f ./mount-s3.rpm

# Create mount directory for S3 bucket
mkdir -p /mnt/s3-dbbackup
chmod 755 /mnt/s3-dbbackup

# Mount S3 backup bucket using AWS Mountpoint
mount-s3 ccms-ebs-${local.environment}-dbbackup /mnt/s3-dbbackup

# Add fstab entry for persistent mounting
echo "ccms-ebs-${local.environment}-dbbackup /mnt/s3-dbbackup fuse.mount-s3 _netdev,allow_other 0 0" >> /etc/fstab
EOF
  )

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(local.tags,
    { Name = lower(format("ec2-%s-%s-ebsdb-dev-test", local.application_name, local.environment)) },
    { instance-role = "dev-test-ebsdb" },
    { instance-scheduling = local.application_data.accounts[local.environment].instance-scheduling },
    { backup = "false" },
    { test-instance = "true" },
    { development-test = "true" }
  )

  depends_on = [aws_security_group.ec2_sg_ebsdb]

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
