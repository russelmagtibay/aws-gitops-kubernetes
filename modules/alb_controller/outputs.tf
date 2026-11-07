output "release_name" {
  description = "Helm release name"
  value       = helm_release.aws_load_balancer_controller.name
}

output "release_version" {
  description = "Helm chart version deployed"
  value       = helm_release.aws_load_balancer_controller.version
}

output "release_namespace" {
  description = "Namespace where the controller was deployed"
  value       = helm_release.aws_load_balancer_controller.namespace
}

