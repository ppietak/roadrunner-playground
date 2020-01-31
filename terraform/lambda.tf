resource "aws_lambda_function" "lambda" {
  function_name = "${local.name}"
  role = "${aws_iam_role.lambda.arn}"

  s3_bucket = "${aws_s3_bucket_object.app.bucket}"
  s3_key = "${aws_s3_bucket_object.app.key}"

  handler = "main"
  runtime = "go1.x"
  timeout = 30
}

resource "aws_iam_role" "lambda" {
  name = "${local.name}-role"
  path = "/services/${var.namespace}/"
  assume_role_policy = "${data.aws_iam_policy_document.lambda.json}"
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

//resource "aws_iam_role_policy_attachment" "duplicate_handler_logs_role_attachment" {
//  role = "${aws_iam_role.duplicate_handler_role.id}"
//  policy_arn = "arn:aws:iam::${var.account}:policy/services/${var.namespace}/LambdaBasicExecution"
//}
//
//resource "aws_iam_role_policy_attachment" "duplicate_handler_ssm_role_attachment" {
//  role = "${aws_iam_role.duplicate_handler_role.id}"
//  policy_arn = "arn:aws:iam::${var.account}:policy/services/${var.namespace}/SecretsAccess"
//}
