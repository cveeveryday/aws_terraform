# examples.tf - Usage examples for the AWS EC2 VM module

# Example 1: Single EC2 instance with only root volume
module "single_ec2_instance" {
  source = "./modules/vm"

  instance_name_prefix     = "web-server"
  instance_count          = 1
  instance_type           = "t3.micro"
  subnet_id              = "subnet-12345678"
  existing_key_pair_name = "my-existing-key"

  # Only root volume (no additional disks)
  root_volume_size = 20
  root_volume_type = "gp3"

  associate_public_ip = true

  tags = {
    Environment = "dev"
    Project     = "web-app"
  }
}

# Example 2: Multiple EC2 instances with data volumes (second disk)
module "multiple_ec2_instances" {
  source = "./modules/vm"

  instance_name_prefix = "app-server"
  instance_count      = 3
  instance_type       = "t3.medium"
  vpc_name           = "my-vpc"
  subnet_name        = "private-subnet-1"

  # Create new key pair
  create_key_pair = true
  public_key      = file("~/.ssh/id_rsa.pub")

  # Root volume configuration
  root_volume_size = 30
  root_volume_type = "gp3"

  # Enable additional data volume (second disk)
  enable_data_volume   = true
  data_volume_size     = 100
  data_volume_type     = "gp3"
  data_volume_device_name = "/dev/sdf"

  # Create Elastic IPs
  create_eip = true

  # Custom security group rules
  security_group_rules = {
    ingress = [
      {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/8"]
        description = "SSH from VPC"
      },
      {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP"
      },
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTPS"
      }
    ]
    egress = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "All outbound"
      }
    ]
  }

  tags = {
    Environment = "prod"
    Application = "web-app"
  }
}

# Example 3: Windows instance with multiple EBS volumes
module "windows_instance" {
  source = "./modules/vm"

  instance_name_prefix     = "win-server"
  instance_count          = 1
  instance_type           = "t3.large"
  subnet_id              = "subnet-12345678"
  existing_key_pair_name = "windows-key"

  # Windows Server AMI
  ami_name_filter = "Windows_Server-2022-English-Full-Base-*"
  ami_owner      = "amazon"

  # Root volume (C: drive)
  root_volume_size = 50
  root_volume_type = "gp3"

  # Additional EBS volumes attached at launch
  additional_ebs_volumes = [
    {
      device_name           = "/dev/sdf"
      volume_type          = "gp3"
      volume_size          = 200
      encrypted            = true
      kms_key_id           = null
      iops                 = 3000
      throughput           = 125
      delete_on_termination = true
    },
    {
      device_name           = "/dev/sdg"
      volume_type          = "gp3"
      volume_size          = 500
      encrypted            = true
      kms_key_id           = null
      iops                 = 4000
      throughput           = 250
      delete_on_termination = false
    }
  ]

  create_eip = true

  # Windows-specific security group
  security_group_rules = {
    ingress = [
      {
        from_port   = 3389
        to_port     = 3389
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/8"]
        description = "RDP"
      },
      {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP"
      }
    ]
    egress = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "All outbound"
      }
    ]
  }

  tags = {
    Environment = "prod"
    OS          = "Windows"
  }
}

# Example 4: Database servers with static IPs and high IOPS storage
module "database_servers" {
  source = "./modules/vm"

  instance_name_prefix     = "db-server"
  instance_count          = 2
  instance_type           = "r5.xlarge"
  subnet_id              = "subnet-87654321"
  existing_key_pair_name = "db-key"

  # Static private IPs
  private_ips = ["10.0.1.100", "10.0.1.101"]

  # High performance root volume
  root_volume_size = 100
  root_volume_type = "io2"
  root_volume_iops = 5000

  # High performance data volume for database
  enable_data_volume   = true
  data_volume_size     = 1000
  data_volume_type     = "io2"
  data_volume_iops     = 10000
  data_volume_device_name = "/dev/sdf"

  # Custom AMI optimized for databases
  ami_id = "ami-0abcdef1234567890"

  # Database-specific security group
  security_group_rules = {
    ingress = [
      {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
        description = "SSH from VPC"
      },
      {
        from_port   = 0
        to_port     = 3306
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
        description = "MySQL access"
      },
      {
        from_port   = 0
        to_port     = 1433
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
        description = "SQL Server access"
      }
    ]
    egress = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "All outbound"
      }
    ]
  }

  tags = {
    Environment = "prod"
    Application = "database"
  }
}