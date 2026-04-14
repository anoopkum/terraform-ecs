resource "aws_iam_role" "ecs_default_task" {
  name = "${var.environment}_${var.cluster}_default_task"
  path = "/ecs/"

  assume_role_policy = file("${path.module}/ecs_default_task.json")
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  policy = templatefile("${path.module}/aws_caller_identity.json", {
    account_id = data.aws_caller_identity.current.account_id
    prefix     = var.prefix
    aws_region = data.aws_region.current.name
  })
}

resource "aws_iam_policy" "ecs_default_task" {
  name = "${var.environment}_${var.cluster}_ecs_default_task"
  path = "/"

  policy = local.policy
}

resource "aws_iam_policy_attachment" "ecs_default_task" {
  name       = "${var.environment}_${var.cluster}_ecs_default_task"
  roles      = [aws_iam_role.ecs_default_task.name]
  policy_arn = aws_iam_policy.ecs_default_task.arn
}
