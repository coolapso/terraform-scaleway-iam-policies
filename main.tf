resource "scaleway_iam_policy" "this" {
  for_each = var.policies

  application_id  = each.value.application_id
  description     = each.value.description
  group_id        = each.value.group_id
  name            = coalesce(each.value.name, each.key)
  no_principal    = each.value.no_principal ? true : null
  organization_id = var.organization_id
  tags            = sort(tolist(setunion(var.tags, each.value.tags)))
  user_id         = each.value.user_id

  dynamic "rule" {
    for_each = each.value.rules

    content {
      condition            = rule.value.condition
      organization_id      = rule.value.organization_id
      permission_set_names = rule.value.permission_set_names
      project_ids          = try(length(rule.value.project_ids) > 0, false) ? sort(tolist(rule.value.project_ids)) : null
    }
  }
}
