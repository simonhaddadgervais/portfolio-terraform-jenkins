#################################
# DYNAMODB

# Create a DynamoDB table
resource "aws_dynamodb_table" "my_table" {
  name           = "VisitCountPortfolio"
  read_capacity  = 10
  write_capacity = 10
  hash_key       = "ID"

  attribute {
    name = "ID"
    type = "S"
  }
}


#################################
# ELASTIC CONTAINER REGISTRY

# Create ECR repository
resource "aws_ecr_repository" "repo" {
  name = "my-app"
}

# Build docker images and push to ECR
resource "docker_registry_image" "repo" {
  name = "${aws_ecr_repository.repo.repository_url}:latest"
}

# Reference the image
data "aws_ecr_image" "ecr_image" {
  depends_on      = [docker_registry_image.repo]
  repository_name = aws_ecr_repository.repo.name
  image_tag       = "latest"
}


#################################
# LAMBDA

# Create the lambda function with the docker image
resource "aws_lambda_function" "test_lambda" {
  function_name = "visitor_count"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 10 # seconds
  image_uri     = "${aws_ecr_repository.repo.repository_url}@${data.aws_ecr_image.ecr_image.id}"
  package_type  = "Image"
}

# Create the role policy for the lambda function to access DynamoDB table
resource "aws_iam_role_policy" "access_to_dynamodb" {
  name = "role_policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
        ],
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:${var.my_region}:${var.accountId}:table/VisitCountPortfolio"
      }
    ]
  })
}

# Create the role for lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# Attach to the lambda role a basic CloudWatch policy
resource "aws_iam_role_policy_attachment" "basic_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#################################
# API GATEWAY

# Create a REST API
resource "aws_api_gateway_rest_api" "rest_api" {
  name = "rest_api"
}


resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "visitors_count"
}

# Create the GET method for the API
resource "aws_api_gateway_method" "api_method" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Create integration between lambda function and the API gateway
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.api_resource.id
  http_method             = aws_api_gateway_method.api_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.test_lambda.invoke_arn
}

# Allow the API Gateway to talk to the lambda function
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.my_region}:${var.accountId}:${aws_api_gateway_rest_api.rest_api.id}/*/${aws_api_gateway_method.api_method.http_method}${aws_api_gateway_resource.api_resource.path}"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  triggers = {
    redeployment = sha256(jsonencode([
      aws_api_gateway_resource.api_resource.id,
      aws_api_gateway_method.api_method.id,
      aws_api_gateway_integration.integration.id,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Create named reference to the deployment
resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  stage_name    = "Prod"
}

resource "aws_api_gateway_integration_response" "response" {
  depends_on  = [aws_api_gateway_integration.integration]
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.api_method.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  # Extract body from the json response
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
$inputRoot.body
EOF
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.api_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}
