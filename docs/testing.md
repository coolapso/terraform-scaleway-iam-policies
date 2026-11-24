# Testing strategy

## Execution assumptions

The module supports OpenTofu `>= 1.12.0, < 2.0.0`; CI uses the version in
`.opentofu-version` and Scaleway provider 2.83.x. It is a reusable leaf module,
so it has no backend or state of its own. Checks run through `Taskfile.yml`.

## Decision matrix

| Situation in this module | Tool | Current decision | Reason |
| --- | --- | --- | --- |
| Formatting, schema, and static checks | `task fmt:check`, `task validate`, TFLint | Use | Free checks catch syntax, schema, and style regressions. |
| Policy contract, principal and rule-scope validation | `tofu test` with `mock_provider` | Use | Names, principals, rules, tags, and validation failures are known during `plan`; no credentials or cloud resources are needed. |
| Permission set names, rule conditions, or API-side policy behavior | Controlled integration test | Do not run by default | Scaleway validates these only on apply. Testing them needs a dedicated organization or project, a reviewed apply, and reliable cleanup. |

Mocked providers skip the Scaleway provider's own configuration checks, so the
module's variable validations are what the rejection tests exercise. Keep a
validation for every input shape the API is known to reject.

`task test:native` and `task ci` do not apply or destroy infrastructure.
Before a real integration test or any production change, run a reviewed
`tofu plan -out=tfplan` in the target root, retain the plan artifact, and apply
that exact reviewed artifact only after approval.
