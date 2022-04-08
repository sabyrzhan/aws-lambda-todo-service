resource "aws_dynamodb_table" "todolist_table" {
  name           = "todolist"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "user_id"
  range_key      = "create_ts"

  attribute {
    name = "user_id"
    type = "N"
  }

  attribute {
    name = "create_ts"
    type = "N"
  }
}