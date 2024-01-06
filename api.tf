resource "aws_api_gateway_vpc_link" "api-gateway-vpc-link" {
  target_arns = [aws_lb.nlb.arn]
  name        = "api-gateway-vpc-link"
}

resource "aws_api_gateway_rest_api" "api-gateway-rest-api" {
  name = "java-ms-java"
}

resource "aws_api_gateway_resource" "api_gateway_resource_health_check_print" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway-rest-api.id
  parent_id   = aws_api_gateway_rest_api.api-gateway-rest-api.root_resource_id
  path_part   = "print"
}

resource "aws_api_gateway_resource" "api_gateway_resource_health_check_actuator" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway-rest-api.id
  parent_id   = aws_api_gateway_resource.api_gateway_resource_health_check_print.id
  path_part   = "actuator"
}

resource "aws_api_gateway_resource" "api_gateway_resource_cue_print" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway-rest-api.id
  parent_id   = aws_api_gateway_resource.api_gateway_resource_health_check_print.id
  path_part   = "cue-print"
}

resource "aws_api_gateway_resource" "api_gateway_resource_v1" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway-rest-api.id
  parent_id   = aws_api_gateway_resource.api_gateway_resource_cue_print.id
  path_part   = "v1"
}

resource "aws_api_gateway_resource" "api_gateway_resource_story" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway-rest-api.id
  parent_id   = aws_api_gateway_resource.api_gateway_resource_v1.id
  path_part   = "story"
}

resource "aws_api_gateway_resource" "api_gateway_resource_send" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway-rest-api.id
  parent_id   = aws_api_gateway_resource.api_gateway_resource_story.id
  path_part   = "send"
}

resource "aws_api_gateway_resource" "api_gateway_resource_health_check_health" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway-rest-api.id
  parent_id   = aws_api_gateway_resource.api_gateway_resource_health_check_actuator.id
  path_part   = "health"
}

resource "aws_api_gateway_method" "api-gateway-method-health" {
  rest_api_id   = aws_api_gateway_rest_api.api-gateway-rest-api.id
  resource_id   = aws_api_gateway_resource.api_gateway_resource_health_check_health.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "api-gateway-method-get" {
  rest_api_id   = aws_api_gateway_rest_api.api-gateway-rest-api.id
  resource_id   = aws_api_gateway_resource.api_gateway_resource_send.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "api-gateway-method-post" {
  rest_api_id   = aws_api_gateway_rest_api.api-gateway-rest-api.id
  resource_id   = aws_api_gateway_resource.api_gateway_resource_send.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "health_check" {
  rest_api_id             = aws_api_gateway_rest_api.api-gateway-rest-api.id
  resource_id             = aws_api_gateway_resource.api_gateway_resource_health_check_health.id
  http_method             = aws_api_gateway_method.api-gateway-method-health.http_method
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_alb.application_load_balancer.dns_name}:8101/print/actuator/health"
  integration_http_method = "GET"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.api-gateway-vpc-link.id
}

resource "aws_api_gateway_integration" "get" {
  rest_api_id             = aws_api_gateway_rest_api.api-gateway-rest-api.id
  resource_id             = aws_api_gateway_resource.api_gateway_resource_send.id
  http_method             = aws_api_gateway_method.api-gateway-method-get.http_method
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_alb.application_load_balancer.dns_name}:8101/print/cue-print/v1/story/send"
  integration_http_method = "GET"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.api-gateway-vpc-link.id
}

resource "aws_api_gateway_integration" "post" {
  rest_api_id             = aws_api_gateway_rest_api.api-gateway-rest-api.id
  resource_id             = aws_api_gateway_resource.api_gateway_resource_send.id
  http_method             = aws_api_gateway_method.api-gateway-method-post.http_method
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_alb.application_load_balancer.dns_name}:8101/print/cue-print/v1/story/send"
  integration_http_method = "POST"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.api-gateway-vpc-link.id
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway-rest-api.id
  stage_name  = "java-ms"

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api-gateway-rest-api.body))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.api-gateway-method-health,
    aws_api_gateway_integration.health_check,
    aws_api_gateway_method.api-gateway-method-get,
    aws_api_gateway_integration.get,
    aws_api_gateway_method.api-gateway-method-post,
    aws_api_gateway_integration.post
  ]
}

resource "aws_api_gateway_account" "demo" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

resource "aws_api_gateway_method_settings" "general_settings" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway-rest-api.id
  stage_name  = aws_api_gateway_deployment.api_deployment.stage_name
  depends_on  = [aws_api_gateway_rest_api.api-gateway-rest-api, aws_api_gateway_deployment.api_deployment]
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    data_trace_enabled     = true
    logging_level          = "INFO"
    throttling_rate_limit  = 100
    throttling_burst_limit = 50
  }
}