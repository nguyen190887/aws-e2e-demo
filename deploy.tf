provider "aws" {
  region = "us-west-2"
}

# Bucket: image
resource "aws_s3_bucket" "ImageBucket" {
  bucket = "rita167.e2edemo.gallery"
  acl    = "private"
}

# Lambda function: Create Image Info
resource "aws_iam_role" "iam_Lambda_CreateImage" {
  name = "e2edemo_Lambda_CreateImage"

  assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": "sts:AssumeRole",
			"Principal": {
				"Service": "lambda.amazonaws.com"
			}
		}
	]
}
EOF
}

resource "aws_iam_role_policy" "iam_policy_CrateImageInfo" {
  name = "iam_policy_CrateImageInfo"
  role = "${aws_iam_role.iam_Lambda_CreateImage.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "dynamodb:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": [
                "logs:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_lambda_function" "CreateImageInfo" {
  filename         = "Lambda.CreateImageInfo.zip"
  function_name    = "e2edemo_CreateImageInfo"
  role             = "${aws_iam_role.iam_Lambda_CreateImage.arn}"
  handler          = "Lambda.CreateImageInfo::Lambda.CreateImageInfo.Function::FunctionHandler"
  source_code_hash = "${base64sha256(file("Lambda.CreateImageInfo.zip"))}"
  runtime          = "dotnetcore2.0"
  timeout          = "10"
}

# Lambda function: Resize Image
resource "aws_iam_role" "iam_Lambda_ResizeImage" {
  name = "e2edemo_Lambda_ResizeImage"

  assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": "sts:AssumeRole",
			"Principal": {
				"Service": "lambda.amazonaws.com"
			}
		}
	]
}
EOF
}

resource "aws_iam_role_policy" "iam_policy_ResizeImage" {
  name = "iam_policy_ResizeImage"
  role = "${aws_iam_role.iam_Lambda_ResizeImage.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:*"
            ],
            "Effect": "Allow",
            "Resource": "${aws_s3_bucket.ImageBucket.arn}/*"
        },
        {
            "Action": [
                "logs:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_lambda_function" "ResizeImage" {
  filename         = "Lambda.ResizeImage.zip"
  function_name    = "e2edemo_ResizeImage"
  role             = "${aws_iam_role.iam_Lambda_ResizeImage.arn}"
  handler          = "index.handler"
  source_code_hash = "${base64sha256(file("Lambda.ResizeImage.zip"))}"
  runtime          = "nodejs8.10"
  timeout          = "10"
}

resource "aws_lambda_permission" "AllowImageBucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.ResizeImage.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.ImageBucket.arn}"
}

resource "aws_s3_bucket_notification" "ImageBucketNotification" {
  bucket = "${aws_s3_bucket.ImageBucket.id}"

  lambda_function = {
    lambda_function_arn = "${aws_lambda_function.ResizeImage.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "images/"
  }
}
