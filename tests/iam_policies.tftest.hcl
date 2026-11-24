mock_provider "scaleway" {
  mock_resource "scaleway_iam_policy" {
    defaults = {
      editable = true
      id       = "11111111-1111-1111-1111-111111111111"
      srn      = "srn:scaleway:iam::22222222-2222-2222-2222-222222222222:policy/11111111-1111-1111-1111-111111111111"
    }
  }
}

run "plans_an_application_policy_scoped_to_projects" {
  command = plan

  variables {
    policies = {
      ci-registry = {
        description    = "CI pushes container images."
        application_id = "33333333-3333-3333-3333-333333333333"
        tags           = ["ci"]
        rules = [{
          permission_set_names = ["ContainerRegistryFullAccess"]
          project_ids = [
            "55555555-5555-5555-5555-555555555555",
            "44444444-4444-4444-4444-444444444444",
          ]
        }]
      }
    }
    tags = ["iam", "native-test"]
  }

  assert {
    condition     = scaleway_iam_policy.this["ci-registry"].name == "ci-registry"
    error_message = "The policy name must default to its map key."
  }

  assert {
    condition     = scaleway_iam_policy.this["ci-registry"].application_id == "33333333-3333-3333-3333-333333333333"
    error_message = "The application principal must be passed to the policy."
  }

  assert {
    condition     = scaleway_iam_policy.this["ci-registry"].no_principal == null
    error_message = "no_principal must stay unset when a principal is bound."
  }

  assert {
    condition     = scaleway_iam_policy.this["ci-registry"].tags == tolist(["ci", "iam", "native-test"])
    error_message = "Module and policy tags must be merged and sorted."
  }

  assert {
    condition     = scaleway_iam_policy.this["ci-registry"].rule[0].permission_set_names == toset(["ContainerRegistryFullAccess"])
    error_message = "Permission sets must be passed to the rule."
  }

  assert {
    condition = scaleway_iam_policy.this["ci-registry"].rule[0].project_ids == tolist([
      "44444444-4444-4444-4444-444444444444",
      "55555555-5555-5555-5555-555555555555",
    ])
    error_message = "Rule project IDs must be passed in a stable order."
  }

  assert {
    condition     = scaleway_iam_policy.this["ci-registry"].rule[0].organization_id == null
    error_message = "A project-scoped rule must not set organization_id."
  }

  assert {
    condition     = output.policies["ci-registry"].id == "11111111-1111-1111-1111-111111111111"
    error_message = "policies must return the provider policy ID keyed by the input key."
  }
}

run "plans_organization_and_detached_policies" {
  command = plan

  variables {
    organization_id = "22222222-2222-2222-2222-222222222222"
    policies = {
      platform-read-only = {
        name     = "platform-team-read-only"
        group_id = "66666666-6666-6666-6666-666666666666"
        rules = [
          {
            permission_set_names = ["IAMReadOnly"]
            organization_id      = "22222222-2222-2222-2222-222222222222"
            condition            = "request.user_agent == 'native-test'"
          },
          {
            permission_set_names = ["ContainerRegistryReadOnly"]
            project_ids          = ["44444444-4444-4444-4444-444444444444"]
          },
        ]
      }
      detached = {
        no_principal = true
        rules = [{
          permission_set_names = ["IAMReadOnly"]
          organization_id      = "22222222-2222-2222-2222-222222222222"
        }]
      }
    }
  }

  assert {
    condition     = scaleway_iam_policy.this["platform-read-only"].name == "platform-team-read-only"
    error_message = "An explicit policy name must override the map key."
  }

  assert {
    condition     = scaleway_iam_policy.this["platform-read-only"].organization_id == "22222222-2222-2222-2222-222222222222"
    error_message = "The policy must be created in the supplied organization."
  }

  assert {
    condition     = scaleway_iam_policy.this["platform-read-only"].group_id == "66666666-6666-6666-6666-666666666666"
    error_message = "The group principal must be passed to the policy."
  }

  assert {
    condition     = length(scaleway_iam_policy.this["platform-read-only"].rule) == 2
    error_message = "Every requested rule must be passed to the policy."
  }

  assert {
    condition     = scaleway_iam_policy.this["platform-read-only"].rule[0].organization_id == "22222222-2222-2222-2222-222222222222"
    error_message = "An organization-scoped rule must pass organization_id."
  }

  assert {
    condition     = scaleway_iam_policy.this["platform-read-only"].rule[0].project_ids == null
    error_message = "An organization-scoped rule must not set project_ids."
  }

  assert {
    condition     = scaleway_iam_policy.this["platform-read-only"].rule[0].condition == "request.user_agent == 'native-test'"
    error_message = "Rule conditions must be passed to the provider."
  }

  assert {
    condition     = scaleway_iam_policy.this["detached"].no_principal
    error_message = "A detached policy must set no_principal."
  }

  assert {
    condition     = length(scaleway_iam_policy.this["detached"].tags) == 0
    error_message = "A policy without tags must receive an empty tag list."
  }
}

run "rejects_a_policy_with_two_principals" {
  command = plan

  variables {
    policies = {
      invalid = {
        application_id = "33333333-3333-3333-3333-333333333333"
        group_id       = "66666666-6666-6666-6666-666666666666"
        rules = [{
          permission_set_names = ["IAMReadOnly"]
          organization_id      = "22222222-2222-2222-2222-222222222222"
        }]
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_a_policy_without_a_principal" {
  command = plan

  variables {
    policies = {
      invalid = {
        rules = [{
          permission_set_names = ["IAMReadOnly"]
          organization_id      = "22222222-2222-2222-2222-222222222222"
        }]
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_a_policy_without_rules" {
  command = plan

  variables {
    policies = {
      invalid = {
        application_id = "33333333-3333-3333-3333-333333333333"
        rules          = []
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_a_rule_without_permission_sets" {
  command = plan

  variables {
    policies = {
      invalid = {
        application_id = "33333333-3333-3333-3333-333333333333"
        rules = [{
          permission_set_names = []
          organization_id      = "22222222-2222-2222-2222-222222222222"
        }]
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_a_rule_with_both_scopes" {
  command = plan

  variables {
    policies = {
      invalid = {
        application_id = "33333333-3333-3333-3333-333333333333"
        rules = [{
          permission_set_names = ["IAMReadOnly"]
          organization_id      = "22222222-2222-2222-2222-222222222222"
          project_ids          = ["44444444-4444-4444-4444-444444444444"]
        }]
      }
    }
  }

  expect_failures = [var.policies]
}

run "rejects_a_rule_without_a_scope" {
  command = plan

  variables {
    policies = {
      invalid = {
        application_id = "33333333-3333-3333-3333-333333333333"
        rules = [{
          permission_set_names = ["IAMReadOnly"]
          project_ids          = []
        }]
      }
    }
  }

  expect_failures = [var.policies]
}
