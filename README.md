# hmpps-reporting-workflows

Central GitHub Actions library for HMPPS Digital Prison Reporting repos —
the CircleCI-orb equivalent of `hmpps-reporting-orb`, but for GitHub
Actions. Consuming repos hold only thin trigger-stub workflow files; all
real build/test/deploy/security logic lives here, versioned and reused.

## Versioning

Consumers pin to a semver git tag (e.g. `@v1`), never `@main`. See
[`docs/versioning.md`](docs/versioning.md) for the tagging convention and
what counts as a breaking change.

## Layout

- `.github/workflows/` — reusable `workflow_call` workflows:
  - `reporting_pipeline.yml` — dual-track build/deploy orchestrator
  - `pr_checks.yml` — PR lint/coverage checks
  - `gradle_validate.yml`, `helm_lint.yml`, `docker_build.yml`,
    `deploy_env.yml` — stack-agnostic primitives
  - `security_*.yml` — thin proxies wrapping
    `ministryofjustice/hmpps-github-actions`, so consumers never reference
    it directly
  - `security_drift_check.yml` — guards against the wrapped upstream
    security workflows going stale
- `actions/` — composite actions shared across reusable workflows
  (e.g. `bump-lib-version`)
- `templates/` — copy-paste starter files for consuming repos' thin
  caller workflows
- `docs/` — process documentation (versioning, upgrade process)

## Consuming this library

Copy the relevant file(s) from `templates/` into the consuming repo's
`.github/workflows/`, fill in the repo-specific inputs (chart names,
release names, toggles), and pin the `uses:` ref to a released tag.