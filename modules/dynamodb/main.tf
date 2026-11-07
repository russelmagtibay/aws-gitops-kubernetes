resource "aws_dynamodb_table" "this" {
  name         = var.table_name != "" ? var.table_name : "${var.project_name}-${var.environment}-leads"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-leads"
    Environment = var.environment
  }
}

