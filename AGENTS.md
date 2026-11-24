# Working on this module

This repository contains an OpenTofu module that creates Scaleway IAM policies.
Keep changes focused and use the Taskfile as the entry point for local and CI
work.

## Commands

Run `task --list` before choosing a task. The normal verification command is
`task ci`; it runs formatting, OpenTofu validation, TFLint, terraform-docs,
GitHub Actions linting, and native OpenTofu tests. Use `task docs` after
changing inputs, outputs, provider constraints, or resource declarations. It
regenerates the marked section of `README.md`; do not hand-edit that section.

`task lint`, `task docs`, and `task workflow:lint` use pinned Docker images; do
not add local TFLint, terraform-docs, or actionlint installations.
`task test:native` runs native OpenTofu tests with a mocked Scaleway provider
and `command = plan`. It must never gain an apply, destroy, real key, state
file, or production fixture. Tests should assert a user-visible resource
contract from the plan. See [docs/testing.md](docs/testing.md) before adding
Terratest or a real-cloud integration test.

Use `task release:check` to run all checks and preview the next release. Use
`task release` only from a clean `main` checkout with a `SEMREL_PLUGIN_TOKEN`
GitHub credential; it creates and pushes a Git tag and a GitHub Release. It
never writes a changelog, version file, or release commit. Semrel derives
versions from Conventional Commit messages.

## OpenTofu conventions

- Keep the root module compatible with OpenTofu `>= 1.12.0, < 2.0.0` and the
  Scaleway provider `~> 2.83` unless a deliberate compatibility change is
  documented.
- `scaleway_iam_policy.this` uses `for_each` over the `policies` map. A map key
  is the policy's state identity: renaming a key destroys and recreates that
  policy unless a `moved` block is added. Never switch to `count`.
- IAM policies belong to an organization and have no region or zone. A policy
  binds exactly one principal (`application_id`, `group_id`, `user_id`, or
  `no_principal = true`), and each rule is scoped to either `project_ids` or
  `organization_id`. Keep the variable validations that enforce this; mocked
  tests depend on them because the mock provider skips provider-side checks.
- Send `null`, not `false` or an empty list, for unused provider arguments
  such as `no_principal` and `project_ids`.
- Keep input descriptions clear, add validation when it prevents a known
  provider failure, and mark only secret-derived outputs `sensitive`.
- Examples are independently linted OpenTofu roots. Give each example its own
  OpenTofu and provider constraints, and keep them valid with the current
  provider schema.
- Do not commit `.terraform/`, `.tofu/`, `.terraform.lock.hcl`, `.tofu.lock.hcl`,
  state, plans, provider credentials, or semrel plugin binaries.

## Change discipline

Use Conventional Commit messages. Run the smallest relevant Task targets while
editing, then `task ci` before handing off. Make a focused commit for each
independent milestone. If an interruption leaves work incomplete, record the
actual remaining verification or implementation work in `TODO.md`.
