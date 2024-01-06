resource "aws_lb" "nlb" {
  name               = "java-ms-java-nlb"
  load_balancer_type = "network"
  subnets            = [aws_subnet.private_subnets.id, aws_subnet.private_subnets_a.id]
  internal           = true
}

resource "aws_lb_listener" "listener-nlb" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "8101"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group" "tg" {
  name        = "java-ms-java-lb-tg"
  port        = 8101
  protocol    = "TCP"
  target_type = "alb"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    healthy_threshold   = "3"
    interval            = "300"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/print/actuator/health"
    unhealthy_threshold = "2"
  }
}

resource "aws_lb_target_group_attachment" "nlb-tg-attachment" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_alb.application_load_balancer.id
  port             = aws_lb_listener.listener.port
}

resource "aws_alb" "application_load_balancer" {
  name               = "java-ms-alb"
  internal           = true
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnets.id, aws_subnet.public_subnets_a.id]
  security_groups    = [aws_security_group.load_balancer_security_group.id]

  tags = {
    Name = "java-ms-alb"
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "java-ms-tg"
  port        = 8101
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    healthy_threshold   = "3"
    interval            = "300"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/print/actuator/health"
    unhealthy_threshold = "2"
  }

  tags = {
    Name = "java-ms-lb-tg"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.id
  port              = "8101"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.id
  }
}