locals {
  organization_id = "22222222-2222-2222-2222-222222222222"
}

terraform {
  source = "../../"
}

inputs = {
  organization_id = local.organization_id

  policies = {
    ci-registry-push = {
      description    = "Lets the CI application push images to the production registry."
      application_id = "33333333-3333-3333-3333-333333333333"
      rules = [{
        permission_set_names = ["ContainerRegistryFullAccess"]
        project_ids          = ["44444444-4444-4444-4444-444444444444"]
      }]
    }

    platform-read-only = {
      name     = "platform-team-read-only"
      group_id = "66666666-6666-6666-6666-666666666666"
      rules = [{
        permission_set_names = ["IAMReadOnly"]
        organization_id      = local.organization_id
      }]
    }
  }

  tags = ["example", "iam"]
}
