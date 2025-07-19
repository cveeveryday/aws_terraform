# variables.tf for AWS EC2 vm module

variable "instance_name_prefix" {
  description = "Prefix for instance names"
  type        = string
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 100
    error_message = "Instance count must be between 1 and 100."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# VPC and Subnet Configuration
variable "vpc_id" {
  description = "VPC ID where instances will be created"
  type        = string
  default     = null
}

variable "vpc_name" {
  description = "VPC name (if vpc_id is not provided)"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Subnet ID where instances will be deployed"
  type        = string
  default     = null
}

variable "subnet_name" {
  description = "Subnet name (if subnet_id is not provided)"
  type        = string
  default     = null
}

variable "private_ips" {
  description = "List of private IP addresses to assign to instances"
  type        = list(string)
  default     = []
}

# AMI Configuration
variable "ami_id" {
  description = "AMI ID to use for instances"
  type        = string
  default     = null
}

variable "ami_name_filter" {
  description = "AMI name filter (used if ami_id is not specified)"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
}

variable "ami_owner" {
  description = "AMI owner (used if ami_id is not specified)"
  type        = string
  default     = "099720109477" # Canonical
}

# Key Pair Configuration
variable "create_key_pair" {
  description = "Create a new key pair"
  type        = bool
  default     = false
}

variable "public_key" {
  description = "Public key content (required if create_key_pair is true)"
  type        = string
  default     = null
}

variable "existing_key_pair_name" {
  description = "Name of existing key pair"
  type        = string
  default     = null
}

# Root Volume Configuration
variable "root_volume_type" {
  description = "Type of root volume"
  type        = string
  default     = "gp3"
  
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2", "sc1", "st1"], var.root_volume_type)
    error_message = "Root volume type must be one of: gp2, gp3, io1, io2, sc1, st1."
  }
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 20
}

variable "root_volume_encrypted" {
  description = "Encrypt root volume"
  type        = bool
  default     = true
}

variable "root_volume_kms_key_id" {
  description = "KMS key ID for root volume encryption"
  type        = string
  default     = null
}

variable "root_volume_iops" {
  description = "IOPS for root volume (only for gp3, io1, io2)"
  type        = number
  default     = 3000
}

variable "root_volume_throughput" {
  description = "Throughput for root volume (only for gp3)"
  type        = number
  default     = 125
}

variable "root_volume_delete_on_termination" {
  description = "Delete root volume on instance termination"
  type        = bool
  default     = true
}

# Data Volume Configuration (separate EBS volume)
variable "enable_data_volume" {
  description = "Create additional data volume"
  type        = bool
  default     = false
}

variable "data_volume_size" {
  description = "Size of data volume in GB"
  type        = number
  default     = 100
}

variable "data_volume_type" {
  description = "Type of data volume"
  type        = string
  default     = "gp3"
  
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2", "sc1", "st1"], var.data_volume_type)
    error_message = "Data volume type must be one of: gp2, gp3, io1, io2, sc1, st1."
  }
}

variable "data_volume_encrypted" {
  description = "Encrypt data volume"
  type        = bool
  default     = true
}

variable "data_volume_kms_key_id" {
  description = "KMS key ID for data volume encryption"
  type        = string
  default     = null
}

variable "data_volume_iops" {
  description = "IOPS for data volume (only for gp3, io1, io2)"
  type        = number
  default     = 3000
}

variable "data_volume_throughput" {
  description = "Throughput for data volume (only for gp3)"
  type        = number
  default     = 125
}

variable "data_volume_device_name" {
  description = "Device name for data volume"
  type        = string
  default     = "/dev/sdf"
}

# Additional EBS Volumes (inline with instance)
variable "additional_ebs_volumes" {
  description = "List of additional EBS volumes to attach"
  type = list(object({
    device_name           = string
    volume_type           = string
    volume_size           = number
    encrypted             = bool
    kms_key_id            = string
    iops                  = number
    throughput            = number
    delete_on_termination = bool
  }))
  default = []
}

# Network Configuration
variable "associate_public_ip" {
  description = "Associate public IP address"
  type        = bool
  default     = false
}

variable "create_eip" {
  description = "Create Elastic IP addresses"
  type        = bool
  default     = false
}

# Security Group Configuration
variable "create_security_group" {
  description = "Create new security group"
  type        = bool
  default     = true
}

variable "existing_security_group_ids" {
  description = "List of existing security group IDs (if not creating new one)"
  type        = list(string)
  default     = []
}

variable "security_group_rules" {
  description = "Security group rules"
  type = object({
    ingress = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = string
    }))
    egress = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = string
    }))
  })
  default = {
    ingress = [
      {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["127.0.0.1/0"]
        description = "SSH access"
      }
    ]
    egress = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "All outbound traffic"
      }
    ]
  }
}

# Instance Configuration
variable "user_data" {
  description = "User data script"
  type        = string
  default     = null
}

variable "user_data_base64" {
  description = "Base64 encoded user data"
  type        = string
  default     = null
}

variable "user_data_replace_on_change" {
  description = "Replace instance when user data changes"
  type        = bool
  default     = false
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
  default     = null
}

variable "detailed_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}

variable "disable_api_termination" {
  description = "Disable API termination"
  type        = bool
  default     = false
}

variable "disable_api_stop" {
  description = "Disable API stop"
  type        = bool
  default     = false
}

variable "instance_initiated_shutdown_behavior" {
  description = "Instance shutdown behavior"
  type        = string
  default     = "stop"
  
  validation {
    condition     = contains(["stop", "terminate"], var.instance_initiated_shutdown_behavior)
    error_message = "Instance shutdown behavior must be either 'stop' or 'terminate'."
  }
}

variable "enable_volume_tags" {
  description = "Enable volume tags"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}