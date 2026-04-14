output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.app.name
}

output "service_arn" {
  description = "ECS service ARN"
  value       = aws_ecs_service.app.id
}

output "task_definition_arn" {
  description = "Task definition ARN"
  value       = aws_ecs_task_definition.app.arn
}

output "task_definition_family" {
  description = "Task definition family"
  value       = aws_ecs_task_definition.app.family
}

output "target_group_blue_name" {
  description = "Blue target group name"
  value       = aws_lb_target_group.blue.name
}

output "target_group_blue_arn" {
  description = "Blue target group ARN"
  value       = aws_lb_target_group.blue.arn
}

output "target_group_green_name" {
  description = "Green target group name"
  value       = aws_lb_target_group.green.name
}

output "target_group_green_arn" {
  description = "Green target group ARN"
  value       = aws_lb_target_group.green.arn
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.app.name
}
