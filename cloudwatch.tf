resource "aws_cloudwatch_log_group" "log-group" {
  name = "java-ms-logs"

  tags = {
    Application = "java-ms"
  }
}