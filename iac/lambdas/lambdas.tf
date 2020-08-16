variable "lambda_name" {
  default = "nill"
}
variable "phx_prefix" {}

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

resource "aws_iam_role" "lambda_iam_role" {
  name = "${var.lambda_name}_iam_role"

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
      FOO = 111
      BAR = 222
    }
  }
}
