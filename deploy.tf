provider "aws" {
  region     = "us-west-2"
}

resource "aws_iam_role" "iam_CreateImageInfo" {
  name = "Resource-Creation-Tagger-Role"
	
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
  name            = "iam_policy_CrateImageInfo",
  role = "${aws_iam_role.iam_CreateImageInfo.id}",

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
  function_name    = "CreateImageInfo"
  role             = "${aws_iam_role.iam_CreateImageInfo.arn}"
  handler          = "Lambda.CreateImageInfo::Lambda.CreateImageInfo.Function::FunctionHandler"
  source_code_hash = "${base64sha256(file("Lambda.CreateImageInfo.zip"))}"
  runtime          = "dotnetcore2.0"
  timeout          = "10"
}
