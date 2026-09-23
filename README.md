# hmpps-reporting-workflows

Central GitHub Actions **orchestrator** library for HMPPS Digital Prison
Reporting — the reusable-workflow equivalent of Cloud Platform CircleCI
config from [`hmpps-circleci-orb`](https://github.com/ministryofjustice/hmpps-circleci-orb)
(`ministryofjustice/hmpps@11`).

Consuming repos hold only thin trigger-stub workflow files. Build / test /
deploy / security job graphs live here. Step-level composites live in
[`hmpps-reporting-actions`](https://github.com/ministryofjustice/hmpps-reporting-actions).

## Versioning

Consumers pin to a semver git tag (e.g. `@v1`), never `@main`. See
[`docs/versioning.md`](docs/versioning.md).

Pushing to `main` auto-creates the next patch tags via
[`.github/workflows/release.yml`](.github/workflows/release.yml).
Use **workflow_dispatch** for minor/major bumps.

## Layout

- `.github/workflows/` — reusable `workflow_call` workflows:
  - `frontend_java_pipeline.yml` — Gradle/Kotlin build/deploy (primary + optional probation)
  - `frontend_node_pipeline.yml` — Node build/deploy (primary + optional probation)
  - `pr_checks.yml` — PR checks (`stack: gradle|node`)
  - `gradle_validate.yml`, `node_validate.yml`, `helm_lint.yml`,
    `docker_build.yml`, `deploy_env.yml` — primitives
  - `security_*.yml` — proxies wrapping `hmpps-github-actions`
  - `security_drift_check.yml` — upstream pin drift guard
  - `validate.yml` — actionlint, shellcheck, unit tests
- Step building blocks live in `hmpps-reporting-actions`
  (`setup-node-npm`, `bump-version`, `update-sentry-release-secret`) — workflows call them via `@v1`
- `scripts/` — shared shell helpers used by workflows / unit-tested locally
- `templates/` — copy-paste thin callers for apps
  (`pipeline-java.yml`, `pipeline-node.yml`, …)
- `docs/` — versioning / process docs

### Deploy model

One Docker image, **primary** Helm product always. Optional named preset:

```yaml
with:
  enable-probation: true   # uses workflow defaults for chart/envs
  # probation-chart-name: …  # override only if needed
```

Other Java/Node apps leave `enable-probation` false (default). Future products
should be further **named** presets (e.g. activities), not numbered flags.

### Optional Sentry (primary deploys)

Matches CircleCI MI-UI `update_sentry_git_ref_secret`: before each **primary**
Helm deploy, optionally patch a Kubernetes secret key (default
`RELEASE_GIT_SHA`) with the raw git SHA of the artifact being deployed
(`Build.<sha>` → `<sha>`). Probation deploys are never patched (same as
CircleCI).

Cloud Platform Terraform does **not** create or manage the Sentry secret; it
must already exist in the target namespace.

```yaml
with:
  enable-sentry: true
  sentry-secret-name: hmpps-digital-prison-reporting-mi-ui-sentry
```

Defaults keep Sentry off for existing consumers (non-breaking).

Docker builds optionally mount BuildKit secret `SENTRY_AUTH_TOKEN` (via
`secrets: inherit`) for apps whose Dockerfile uploads source maps. Leave the
secret unset to skip upload.

## App stub convention

Every consuming app uses the same filenames:

```text
.github/workflows/
  pipeline.yml        # push / workflow_dispatch
  pull-request.yml    # pull_request
  schedule.yml        # scheduled security
```

Copy from `templates/`, fill repo-specific `with:` inputs, pin `@v1`.

## Related

- Actions: `ministryofjustice/hmpps-reporting-actions`
- CircleCI source of truth for MI/MI-UI: `ministryofjustice/hmpps-circleci-orb`
