# define lambdas/subscriptions/cloudwatch
# TODO: specificically define S3 ARN for R and RW access from lambda via var/module

variable "lambda_name" {
  default = "nill"
}
variable "phx_prefix" {}
variable "s3_rw_buckets" {
  description = "List of the bucket with RW access from the lambda function"
  type    = set(string)
  default = []
}

# Compile/provision lambda 
resource "null_resource" "build_lambda" {
  provisioner "local-exec" {
    command = "cd ../lambdas/${var.lambda_name} && make"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../lambdas/${var.lambda_name}/main"
  output_path = "../lambdas/${var.lambda_name}/function.zip"

  depends_on = [
    null_resource.build_lambda
  ]
}

# customize roles by defining and passing variables from modules definition (if needed in future)
resource "aws_iam_role" "lambda_iam_role" {
  name = "${var.phx_prefix}_lambda_${var.lambda_name}_iam_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

### CloudWatch
# customize roles by defining and passing variables from modules definition (if needed in future)
resource "aws_iam_policy" "lambda_logging" {
  name        = "${var.phx_prefix}_lambda_${var.lambda_name}_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

### S3
# customize roles by defining and passing variables from modules definition (if needed in future)
resource "aws_iam_policy" "lambda_s3_rw_access" {
  for_each = var.s3_rw_buckets

  name        = "${var.phx_prefix}_lambda_${var.lambda_name}_lambda_s3_rw_access_${each.value}"
  path        = "/"
  description = "IAM policy for RW access to S3 from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::${each.value}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::${each.value}/*"]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_s3_rw_access" {
  for_each = var.s3_rw_buckets

  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = aws_iam_policy.lambda_s3_rw_access[each.value].arn
}

resource "aws_lambda_function" "app_lambda" {
  filename      = "../lambdas/${var.lambda_name}/function.zip"
  function_name = "${var.phx_prefix}-${var.lambda_name}"
  role          = aws_iam_role.lambda_iam_role.arn
  handler       = "main"
  timeout       = 900

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  #source_code_hash = filebase64sha256("../lambdas/${var.lambda_name}/function.zip")
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime = "go1.x"

  environment {
    variables = {
      LOG_LEVEL = "DEBUG"
    }
  }
  depends_on = [
    aws_cloudwatch_log_group.lambda_cloudwatch,
  ]
}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "lambda_cloudwatch" {
  name              = "/aws/lambda/${var.phx_prefix}-${var.lambda_name}"
  retention_in_days = 14
}

output "type" {
  value = "lambda"
}
output "arn" {
  value = aws_lambda_function.app_lambda.arn
}