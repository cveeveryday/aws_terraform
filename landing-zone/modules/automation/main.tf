# CodeCommit Repositories
resource "aws_codecommit_repository" "repos" {
  for_each = {
    for repo in var.git_repositories : repo.name => repo
  }
  
  repository_name = each.value.name
  description     = each.value.description
  
  tags = merge(var.common_tags, {
    Name = each.value.name
    Type = "SourceControl"
  })
}

# S3 Bucket for CI/CD Artifacts
resource "aws_s3_bucket" "cicd_artifacts" {
  bucket = "${var.organization}-cicd-artifacts-${random_id.bucket_suffix.hex}"
  
  tags = merge(var.common_tags, {
    Name = "CICD-Artifacts"
    Type = "Automation"
  })
}

resource "aws_s3_bucket_versioning" "cicd_artifacts" {
  bucket = aws_s3_bucket.cicd_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Immutable Backup Bucket
resource "aws_s3_bucket" "backup_immutable" {
  bucket = "${var.organization}-backup-immutable-${random_id.bucket_suffix.hex}"
  
  tags = merge(var.common_tags, {
    Name = "Backup-Immutable"
    Type = "Governance"
  })
}

resource "aws_s3_bucket_object_lock_configuration" "backup_immutable" {
  bucket = aws_s3_bucket.backup_immutable.id
  
  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = var.backup_config.backup_retention_days
    }
  }
}

# Cross-region replication for backup
resource "aws_s3_bucket_replication_configuration" "backup_replication" {
  count = var.backup_config.enable_cross_region_backup ? 1 : 0
  
  role   = aws_iam_role.replication[0].arn
  bucket = aws_s3_bucket.backup_immutable.id
  
  rule {
    id     = "backup-replication"
    status = "Enabled"
    
    destination {
      bucket        = aws_s3_bucket.backup_immutable_dr[0].arn
      storage_class = "STANDARD_IA"
    }
  }
  
  depends_on = [aws_s3_bucket_versioning.backup_immutable]
}

# DR Backup Bucket
resource "aws_s3_bucket" "backup_immutable_dr" {
  count = var.backup_config.enable_cross_region_backup ? 1 : 0
  
  provider = aws.secondary
  bucket   = "${var.organization}-backup-immutable-dr-${random_id.bucket_suffix.hex}"
  
  tags = merge(var.common_tags, {
    Name = "Backup-Immutable-DR"
    Type = "Governance"
  })
}