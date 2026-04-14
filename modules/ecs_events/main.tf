resource "aws_sns_topic" "ecs_events" {
  name = "ecs_events_${var.environment}_${var.cluster}"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  ecs_task_stopped_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Task State Change"]
    detail = {
      clusterArn    = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster}"]
      lastStatus    = ["STOPPED"]
      stoppedReason = ["Essential container in task exited"]
    }
  })
}

resource "aws_cloudwatch_event_rule" "ecs_task_stopped" {
  name          = "${var.environment}_${var.cluster}_task_stopped"
  description   = "${var.environment}_${var.cluster} Essential container in task exited"
  event_pattern = local.ecs_task_stopped_pattern
}

resource "aws_cloudwatch_event_target" "event_fired" {
  rule  = aws_cloudwatch_event_rule.ecs_task_stopped.name
  arn   = aws_sns_topic.ecs_events.arn
  input = jsonencode({
    message    = "Essential container in task exited"
    account_id = data.aws_caller_identity.current.account_id
    cluster    = var.cluster
  })
}
