resource "aws_s3_bucket_object" "app" {
  bucket = "${var.lambda_s3_bucket}"
  key    = "${var.lambda_s3_key}"
  source = "../tmp/app.zip"

  etag = "${filemd5("../tmp/app.zip")}"
}
