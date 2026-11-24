variable "policies" {
  description = "IAM policies to create, keyed by a stable identifier. name defaults to the key. Each policy binds exactly one principal (application_id, group_id, user_id, or no_principal = true) to one or more rules, and each rule grants permission sets on either project_ids or a whole organization_id."
  type = map(object({
    name           = optional(string)
    description    = optional(string)
    tags           = optional(set(string), [])
    application_id = optional(string)
    group_id       = optional(string)
    user_id        = optional(string)
    no_principal   = optional(bool, false)
    rules = list(object({
      permission_set_names = set(string)
      project_ids          = optional(set(string))
      organization_id      = optional(string)
      condition            = optional(string)
    }))
  }))
  nullable = false

  validation {
    condition = alltrue([
      for key, policy in var.policies :
      length(trimspace(key)) > 0 && (policy.name == null ? true : length(trimspace(policy.name)) > 0)
    ])
    error_message = "policies keys and names must not be empty."
  }

  validation {
    condition = alltrue([
      for policy in values(var.policies) :
      length(compact([policy.application_id, policy.group_id, policy.user_id])) + (policy.no_principal ? 1 : 0) == 1
    ])
    error_message = "Each policy must set exactly one of application_id, group_id, user_id, or no_principal = true."
  }

  validation {
    condition     = alltrue([for policy in values(var.policies) : try(length(policy.rules) > 0, false)])
    error_message = "Each policy must define at least one rule."
  }

  validation {
    condition = alltrue(flatten([
      for policy in values(var.policies) : [
        for rule in coalesce(policy.rules, []) :
        try(length(rule.permission_set_names) > 0, false) &&
        alltrue([for permission_set in coalesce(rule.permission_set_names, []) : length(trimspace(permission_set)) > 0])
      ]
    ]))
    error_message = "Each rule must grant at least one non-empty permission set name."
  }

  validation {
    condition = alltrue(flatten([
      for policy in values(var.policies) : [
        for rule in coalesce(policy.rules, []) :
        (length(compact([rule.organization_id])) > 0) != try(length(rule.project_ids) > 0, false)
      ]
    ]))
    error_message = "Each rule must be scoped to either project_ids or organization_id, not both."
  }
}

variable "organization_id" {
  description = "Scaleway organization ID that owns the policies. If null, the Scaleway provider default is used."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to every policy, merged with each policy's own tags."
  type        = set(string)
  default     = []
  nullable    = false
}
