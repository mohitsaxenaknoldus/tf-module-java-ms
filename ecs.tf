resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "java-ms-cluster"
  tags = {
    Name = "java-ms-ecs"
  }
}

resource "aws_ecs_task_definition" "aws-ecs-task" {
  family = "java-ms-task"

  container_definitions = <<DEFINITION
  [
    {
      "name": "java-ms-container",
      "image": "${aws_ecr_repository.ecr.repository_url}:latest",
      "entryPoint": [],
      "environment": [
        {
          "name": "env",
          "value": "local"
        }
      ],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.log-group.id}",
          "awslogs-region": "ca-central-1",
          "awslogs-stream-prefix": "java-ms"
        }
      },
      "portMappings": [
        {
          "containerPort": 8101,
          "hostPort": 8101
        }
      ],
      "cpu": 256,
      "memory": 512,
      "networkMode": "awsvpc"
    }
  ]
  DEFINITION

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

  tags = {
    Name = "java-ms-ecs-td"
  }
}

data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}

resource "aws_ecs_service" "aws-ecs-service" {
  name                 = "java-ms-ecs-service"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = "${aws_ecs_task_definition.aws-ecs-task.family}:${max(aws_ecs_task_definition.aws-ecs-task.revision, data.aws_ecs_task_definition.main.revision)}"
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    subnets          = [aws_subnet.private_subnets.id, aws_subnet.private_subnets_a.id]
    assign_public_ip = false
    security_groups = [
      aws_security_group.service_security_group.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "java-ms-container"
    container_port   = 8101
  }

  depends_on = [aws_lb_listener.listener]
}