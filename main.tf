terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.24.0"
    }
  }
}


resource "aws_s3_bucket" "myawsimagebucket" {
  bucket = "my-images-bucketz"

  tags = {
    Name        = "imagesforrekognitionbucket"
    Environment = "Dev"
  }

}
#when an image gets uploaded a notification gets triggered whiich then triggers the lambda function
resource "aws_s3_bucket_notification" "my_bucket_notification" {
  bucket = "my-images-bucketz"
  lambda_function {
    events              = ["s3:ObjectCreated:*"]
    lambda_function_arn = aws_lambda_function.rekognition_lambda.arn
  }
  depends_on = [aws_lambda_permission.allow_s3_invoke]
}
# IAM Role for Lambda to assume
resource "aws_iam_role" "iam_for_lambda" {
  name = "rekognition_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_s3_read" {
  name        = "LambdaS3ReadPolicy"
  description = "Policy for Lambda to read from S3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::my-images-bucketz/*"
      },
    ]
  })
}

resource "aws_iam_policy" "rekognitiondetectlabel" {
  name        = "RekognitionDetectLabel"
  description = "policiy to allow lambda to use rekognition"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["rekognition:DetectLabels"]
        Effect   = "Allow"
        Resource = "*"

      }
    ]

  })
}

resource "aws_iam_policy" "lambda_cloudwatch_logs" {
  name        = "LambdaCloudWatchLogsPolicy"
  description = "Policy for Lambda to write to CloudWatch Logs"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

#attaching poliicies to the roles
resource "aws_iam_role_policy_attachment" "rekognitiondetectlabel" {
  policy_arn = aws_iam_policy.rekognitiondetectlabel.arn
  role       = aws_iam_role.iam_for_lambda.name
}

resource "aws_iam_role_policy_attachment" "lambda_s3_read" {
  policy_arn = aws_iam_policy.lambda_s3_read.arn
  role       = aws_iam_role.iam_for_lambda.name
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch" {
  policy_arn = aws_iam_policy.lambda_cloudwatch_logs.arn
  role       = aws_iam_role.iam_for_lambda.name
}



# Lambda function for Rekognition processing
resource "aws_lambda_function" "rekognition_lambda" {
  function_name = "rekognitionLabelFunction"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "automatedetect.lambda_handler"
  runtime       = "python3.8"
  filename      = "lambda_function.zip"
}



#allowing s3 to trigger the lambda function (when we upload an image)
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  principal     = "s3.amazonaws.com"
  function_name = aws_lambda_function.rekognition_lambda.function_name
  source_arn    = aws_s3_bucket.myawsimagebucket.arn
}
