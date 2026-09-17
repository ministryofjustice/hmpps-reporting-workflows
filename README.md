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
  - `bump_version.yml` — bump shared lib (`stack: gradle|node`); SHA pins live here
  - `gradle_validate.yml`, `node_validate.yml`, `helm_lint.yml`,
    `docker_build.yml`, `deploy_env.yml` — primitives
  - `security_*.yml` — proxies wrapping `hmpps-github-actions`
  - `security_drift_check.yml` — upstream pin drift guard
- Step building blocks live in `hmpps-reporting-actions`
  (`setup-node-npm`, `bump-version`). **Only this repo** pins composites to a
  full commit SHA (MoJ org policy), e.g. `@0536501… # v1.0.3`. Apps pin
  workflows `@v1` and never call actions directly — see
  [`docs/versioning.md`](docs/versioning.md#governance-who-pins-what).
- `templates/` — copy-paste thin callers for apps
  (`pipeline-java.yml`, `pipeline-node.yml`, `bump-version.yml`, …)
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

## App stub convention

Every consuming app uses the same filenames:

```text
.github/workflows/
  pipeline.yml        # push / workflow_dispatch
  pull-request.yml    # pull_request
  schedule.yml        # scheduled security
  bump-version.yml    # optional: workflow_dispatch → bump_version.yml@v1
```

Copy from `templates/`, fill repo-specific `with:` inputs, pin `@v1`.
Do not put `hmpps-reporting-actions` SHAs in app stubs.

## Related

- Actions: `ministryofjustice/hmpps-reporting-actions`
- CircleCI source of truth for MI/MI-UI: `ministryofjustice/hmpps-circleci-orb`
