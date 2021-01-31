### Create cloudwatch log group for rps execution output
resource "aws_cloudwatch_log_group" "ecs_fargate_service" {
  name              = "/ecs/${local.app_env}-${var.app_name}-fargate"
  retention_in_days = 60

}

### Create an IAM role for Fargate service
resource "aws_iam_role" "ecs_fargate" {
  name               = "${local.app_env}-${var.app_parent}-${var.app_name}-ecs-fargate-service-role"
  assume_role_policy = file("${path.module}/templates/assume-ecs-task.json")

  tags = merge(
    local.common_tags,
    map(
      "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-ecs-fargate-service-role"
    )
  )
}

data "template_file" "ecs_fargate_role_policy" {
  template = file("${path.module}/templates/ecs-fargate-role-policy.json")

}

### Create an IAM policy for Fargate service
resource "aws_iam_role_policy" "ecs_fargate" {
  name_prefix = "${local.app_env}-${var.app_parent}-${var.app_name}-fargate-role-policy-"
  role        = aws_iam_role.ecs_fargate.id
  policy      = data.template_file.ecs_fargate_role_policy.rendered
}

data "template_file" "wordpress_task_defination" {
  template = file("${path.module}/templates/wordpress-task-defination.yaml")

  vars = {
    ecs_service_name     = "wordpress"
    app_env              = local.app_env
    app_name             = var.app_name
  }
}

### Create wordpress task defination
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "${local.app_env}-${var.app_name}-fargate"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = data.template_file.rps_task_defination.rendered
  task_role_arn            = aws_iam_role.ecs_fargate.arn
  execution_role_arn       = aws_iam_role.ecs_fargate.arn
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024

  tags = merge(
    local.common_tags,
    map(
      "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-fargate-task-defination"
    )
  )
}

resource "aws_ecs_cluster" "wordpress" {
  name = "${local.app_env}-${var.app_name}-wordpress"

  tags = merge(
    local.common_tags,
    map(
      "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-ecs-wordpress-cluster"
    )
  )
}

### Create ECS service for wordpress execution
resource "aws_ecs_service" "wordpress" {
  name            = "${local.app_env}-${var.app_name}"
  cluster         = aws_ecs_cluster.wordpress.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.wordpress.arn
  #desired_count   = 1

  network_configuration {
  subnets          = module.network_sydney.private_app_subnets
  #security_groups  = [module.fargate_sg.security_group_id]
  assign_public_ip = "false"
}
}
