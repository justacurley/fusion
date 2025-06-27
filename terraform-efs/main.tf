resource "aws_efs_file_system" "ecs_persistence" {
  creation_token = "psu-persistence"
  encrypted      = true
  tags = {
    Name = "PSU persistent storage"
  }
}

# EFS Backup Policy - Enable automatic backups
resource "aws_efs_backup_policy" "ecs_persistence_backup" {
  file_system_id = aws_efs_file_system.ecs_persistence.id

  backup_policy {
    status = "ENABLED"
  }
}

# AWS Backup Vault for EFS backups
resource "aws_backup_vault" "efs_backup_vault" {
  name        = "psu-efs-backup-vault"
  kms_key_arn = aws_kms_key.backup_key.arn

  tags = {
    Name        = "PSU EFS Backup Vault"
    Environment = "production"
  }
}

# KMS Key for backup encryption
resource "aws_kms_key" "backup_key" {
  description             = "KMS key for PSU EFS backups"
  deletion_window_in_days = 7

  tags = {
    Name = "PSU EFS Backup Key"
  }
}

resource "aws_kms_alias" "backup_key_alias" {
  name          = "alias/psu-efs-backup-key"
  target_key_id = aws_kms_key.backup_key.key_id
}

# IAM Role for AWS Backup
resource "aws_iam_role" "backup_role" {
  name = "psu-efs-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "PSU EFS Backup Role"
  }
}

# Attach the AWS managed backup policy
resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Backup Plan with multiple schedules
resource "aws_backup_plan" "efs_backup_plan" {
  name = "psu-efs-backup-plan"

  # Daily backups retained for 30 days
  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.efs_backup_vault.name
    schedule          = "cron(0 2 * * ? *)" # 2 AM daily

    start_window      = 60  # 1 hour window to start backup
    completion_window = 120 # 2 hours to complete backup

    lifecycle {
      delete_after = 30 # Delete after 30 days
    }

    recovery_point_tags = {
      BackupType = "Daily"
      Source     = "PSU-EFS"
    }
  }

  # Weekly backups retained for 12 weeks (3 months)
  rule {
    rule_name         = "weekly_backup"
    target_vault_name = aws_backup_vault.efs_backup_vault.name
    schedule          = "cron(0 3 ? * SUN *)" # 3 AM every Sunday

    start_window      = 60
    completion_window = 120

    lifecycle {
      delete_after = 84 # Delete after 12 weeks
    }

    recovery_point_tags = {
      BackupType = "Weekly"
      Source     = "PSU-EFS"
    }
  }

  # Monthly backups retained for 12 months
  rule {
    rule_name         = "monthly_backup"
    target_vault_name = aws_backup_vault.efs_backup_vault.name
    schedule          = "cron(0 4 1 * ? *)" # 4 AM on the 1st of each month

    start_window      = 60
    completion_window = 180 # 3 hours for monthly backup

    lifecycle {
      delete_after = 365 # Delete after 1 year
    }

    recovery_point_tags = {
      BackupType = "Monthly"
      Source     = "PSU-EFS"
    }
  }

  tags = {
    Name        = "PSU EFS Backup Plan"
    Environment = "production"
  }
}

# Backup Selection - Which resources to backup
resource "aws_backup_selection" "efs_backup_selection" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "psu-efs-backup-selection"
  plan_id      = aws_backup_plan.efs_backup_plan.id

  resources = [
    aws_efs_file_system.ecs_persistence.arn
  ]

  condition {
    string_equals {
      key   = "aws:ResourceTag/Name"
      value = "PSU persistent storage"
    }
  }
}

# Optional: Cross-region backup for disaster recovery
resource "aws_backup_plan" "efs_cross_region_backup" {
  name = "psu-efs-cross-region-backup"

  rule {
    rule_name         = "cross_region_weekly"
    target_vault_name = aws_backup_vault.efs_backup_vault.name
    schedule          = "cron(0 5 ? * SAT *)" # 5 AM every Saturday

    start_window      = 60
    completion_window = 180

    # Copy to different region for disaster recovery
    copy_action {
      destination_vault_arn = "arn:aws:backup:us-east-1:${data.aws_caller_identity.current.account_id}:backup-vault:psu-efs-dr-vault"

      lifecycle {
        delete_after = 90 # Keep cross-region backups for 90 days
      }
    }

    lifecycle {
      delete_after = 30 # Local copy deleted after 30 days
    }

    recovery_point_tags = {
      BackupType = "CrossRegion"
      Source     = "PSU-EFS"
    }
  }
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}