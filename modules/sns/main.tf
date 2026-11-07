resource "aws_sns_topic" "this" {
  name              = var.topic_name != "" ? var.topic_name : "${var.project_name}-${var.environment}-alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name        = "${var.project_name}-${var.environment}-alerts"
    Environment = var.environment
  }
}

