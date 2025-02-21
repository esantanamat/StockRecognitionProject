terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.24.0"
    }
  }
}


resource "aws_dynamodb_table" "rekognitionresult" {
  name         = "rekognitionresults"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "item_type"
  range_key    = "count"

  attribute {
    name = "item_type"
    type = "S"
  }

  attribute {
    name = "count"
    type = "N"
  }


  ttl {
    attribute_name = "timestamp"
    enabled        = true
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
    lambda_function_arn = aws_lambda_function.imageprocess_lambda.arn
  }
  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

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
        Action   = ["rekognition:DetectCustomLabels"]
        Effect   = "Allow"
        Resource = "*"

      }
    ]

  })
}
resource "aws_iam_policy" "writetodynamodb" {
  name        = "WriteToDynamoDB"
  description = "Policy for Lambda to write to DynamoDB"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "dynamodb:PutItem"
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:us-east-1:463470969308:table/rekognitionresults"
      },
    ]
  })

}

resource "aws_iam_policy" "lambda_basic_execution" {
  name        = "LambdaBasicExecutionPolicy"
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

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = aws_iam_policy.lambda_basic_execution.arn
  role       = aws_iam_role.iam_for_lambda.name

}


#attaching poliicies to the roles

resource "aws_iam_role_policy_attachment" "writetodynamodb" {
  policy_arn = aws_iam_policy.writetodynamodb.arn
  role       = aws_iam_role.iam_for_lambda.name
}
resource "aws_iam_role_policy_attachment" "rekognitiondetectlabel" {
  policy_arn = aws_iam_policy.rekognitiondetectlabel.arn
  role       = aws_iam_role.iam_for_lambda.name
}

resource "aws_iam_role_policy_attachment" "lambda_s3_read" {
  policy_arn = aws_iam_policy.lambda_s3_read.arn
  role       = aws_iam_role.iam_for_lambda.name
}




resource "aws_lambda_function" "imageprocess_lambda" {
  function_name = "rekognition-image-processor"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "updatecount.process_handler"
  runtime       = "python3.8"
  filename      = "process_function.zip"
}




#allowing s3 to trigger the lambda function (when we upload an image)
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  principal     = "s3.amazonaws.com"
  function_name = aws_lambda_function.imageprocess_lambda.arn
  source_arn    = aws_s3_bucket.myawsimagebucket.arn
}
