variable "sns_name" {
  default = "nill"
}
variable "phx_prefix" {}
variable "endpoint" {
  default = {
    "type"     = "lambda",
    "arn"      = "none"
  }

}


resource "aws_sns_topic" "topic" {
  name = "${var.phx_prefix}-${var.sns_name}"
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
}

resource "aws_sns_topic_subscription" "sns-subscription" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = var.endpoint.type
  endpoint  = var.endpoint.arn

  depends_on = [
    aws_sns_topic.topic
  ]
}

resource "aws_lambda_permission" "with_sns" {
    statement_id = "AllowExecutionFromSNS"
    action = "lambda:InvokeFunction"
    function_name = var.endpoint.arn
    principal = "sns.amazonaws.com"
    source_arn = aws_sns_topic.topic.arn
}