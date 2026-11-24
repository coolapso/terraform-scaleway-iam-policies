![CI](https://github.com/coolapso/terraform-scaleway-iam-policies/actions/workflows/ci.yml/badge.svg?branch=main)
[![OpenTofu](https://img.shields.io/badge/OpenTofu-1F6FEB?logo=opentofu)](https://opentofu.org/)

# OpenTofu Scaleway IAM Policies

A focused OpenTofu module for Scaleway IAM policies. It creates one policy per
entry in the `policies` map. Each policy binds one principal (an IAM
application, group, or user, or no principal at all) to one or more rules that
grant permission sets on specific projects or on a whole organization.

Requires OpenTofu 1.12 or later, Scaleway provider 2.83.x, and credentials that
are allowed to manage IAM, for example through the `IAMManager` permission set.
IAM policies belong to an organization and have no region or zone. The module
does not configure a backend or provider credentials.

## Usage

```hcl
module "iam_policies" {
  source = "coolapso/iam-policies/scaleway"

  policies = {
    ci-registry-push = {
      description    = "Lets the CI application push images to the production registry."
      application_id = scaleway_iam_application.ci.id
      rules = [{
        permission_set_names = ["ContainerRegistryFullAccess"]
        project_ids          = [var.production_project_id]
      }]
    }

    platform-read-only = {
      name     = "platform-team-read-only"
      group_id = scaleway_iam_group.platform.id
      rules = [{
        permission_set_names = ["IAMReadOnly"]
        organization_id      = var.organization_id
      }]
    }
  }

  tags = ["production", "iam"]
}
```

Map keys are the policies' identities in state: renaming a key replaces that
policy, so add a `moved` block when you rename one. `name` defaults to the key.
Set exactly one of `application_id`, `group_id`, `user_id`, or
`no_principal = true` per policy, and scope each rule to either `project_ids`
or `organization_id`. The module rejects other combinations at plan time.

Permission set names and rule `condition` expressions are passed to Scaleway
unchanged; run `scw iam permission-set list` to see the available names. The
`tags` input is merged into every policy's own `tags`.

See the [OpenTofu example](./examples/opentofu), [Terragrunt example](./examples/terragrunt), and [testing strategy](./docs/testing.md).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12.0, < 2.0.0 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | ~> 2.83 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | ~> 2.83 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [scaleway_iam_policy.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/iam_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | Scaleway organization ID that owns the policies. If null, the Scaleway provider default is used. | `string` | `null` | no |
| <a name="input_policies"></a> [policies](#input\_policies) | IAM policies to create, keyed by a stable identifier. name defaults to the key. Each policy binds exactly one principal (application\_id, group\_id, user\_id, or no\_principal = true) to one or more rules, and each rule grants permission sets on either project\_ids or a whole organization\_id. | <pre>map(object({<br/>    name           = optional(string)<br/>    description    = optional(string)<br/>    tags           = optional(set(string), [])<br/>    application_id = optional(string)<br/>    group_id       = optional(string)<br/>    user_id        = optional(string)<br/>    no_principal   = optional(bool, false)<br/>    rules = list(object({<br/>      permission_set_names = set(string)<br/>      project_ids          = optional(set(string))<br/>      organization_id      = optional(string)<br/>      condition            = optional(string)<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to every policy, merged with each policy's own tags. | `set(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_policies"></a> [policies](#output\_policies) | IAM policies keyed by the policies input key. |
<!-- END_TF_DOCS -->

## Contributing

Run `task --list` to discover formatting, validation, linting, documentation,
tests, and CI tasks. `task ci` has no cloud side effects: native OpenTofu tests
use a mocked provider and `command = plan`. `task docs` and `task lint` use
pinned Docker images, so they do not require local terraform-docs or TFLint
installations. `task release:check` runs the full CI suite and previews the
next Semrel release without changing GitHub or git. The GitHub Actions release
job runs only for pushes to `main`, creates a tag and GitHub Release, and
never writes a changelog or release commit.

## Support

If you like this project and want to support or contribute in another way, you
can [:heart: Sponsor Me](https://github.com/sponsors/coolapso) or:

<a href="https://www.buymeacoffee.com/coolapso" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/default-yellow.png" alt="Buy Me A Coffee" style="height: 51px !important;width: 217px !important;" />
</a>
