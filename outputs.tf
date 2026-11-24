output "policies" {
  description = "IAM policies keyed by the policies input key."
  value = {
    for key, policy in scaleway_iam_policy.this : key => {
      editable        = policy.editable
      id              = policy.id
      name            = policy.name
      organization_id = policy.organization_id
      srn             = policy.srn
    }
  }
}
