# Versioning

`hmpps-reporting-workflows` is versioned like a CircleCI orb was: consuming
repos pin to a **semver git tag**, never to `@main`. This lets the library
evolve without silently breaking every consumer on the same day.

Step-level composites live in `hmpps-reporting-actions` and use the same
tagging rules — workflows that call actions should pin `@v1` there and
release this repo after the actions tag exists.

## Tagging convention

- Tags are plain semver: `v1`, `v1.1.0`, `v1.1.1`, `v2.0.0`.
- A **major** tag (`v1`, `v2`, ...) always points at the latest release
  within that major line. It is force-moved forward on every non-breaking
  release so consumers can pin to `@v1` and get non-breaking fixes/features
  automatically, mirroring `semtag`'s behaviour for `hmpps-reporting-orb`.
- A **full** tag (`v1.1.0`) is immutable and only ever created once. Use a
  full tag when a consumer needs to freeze on an exact revision (e.g. while
  validating a migration).
- Recommended default for consumers: pin to the major tag (`@v1`), not a
  full version and never `@main`.

## What counts as a breaking change

A change to `hmpps-reporting-workflows` requires a **major** version bump
(new major tag, e.g. `v2`) when it changes the public contract of any
reusable workflow or composite action in a way an existing caller cannot
absorb silently. That includes:

- Removing or renaming a `workflow_call` / composite action `input`,
  `output`, or `secret`.
- Changing an input from optional to `required: true`.
- Changing the meaning of an existing input's value (e.g. a path that used
  to be relative to repo root now being relative to `helm-dir`).
- Changing default behaviour that a caller relying on the default would
  visibly experience (e.g. flipping a default from `false` to `true`).
- Renaming a job (`needs:` targets, and any consumer using
  `needs.<job>.outputs` in a nested caller, break).
- Removing a workflow or composite action file, or moving its path.
- Bumping the pinned `ministryofjustice/hmpps-github-actions` ref inside a
  security proxy workflow in a way that changes its inputs/outputs contract
  (a pure security-content bump with the same interface is **not**
  breaking — see below).

A change is **non-breaking** (minor/patch, same major tag moves forward)
when it:

- Adds a new optional input/output/secret with a sensible default.
- Adds a new reusable workflow, composite action, or template file.
- Fixes a bug in existing step logic without changing the declared
  `inputs`/`outputs`/`secrets` contract or observable defaults.
- Bumps a wrapped upstream workflow ref (e.g.
  `ministryofjustice/hmpps-github-actions@vX`) to a newer compatible
  version, keeping the same passthrough inputs.
- Improves documentation, comments, or internal step names.

When in doubt, treat the change as breaking — it is far cheaper for the
library owner to cut an extra major tag than for every consumer to debug a
silently-changed pipeline.

## Release process

Tags are created automatically by [`.github/workflows/release.yml`](../.github/workflows/release.yml):

1. Land the change on `main` via PR review as normal.
2. On push to `main`, the workflow **patch-bumps** by default:
   - Creates immutable full tag `vX.Y.Z`
   - Force-moves moving tags `vX` and `vX.Y` to the same commit
   - Creates a GitHub Release with generated notes
3. For a **minor** or **major** (breaking) bump, run **Actions → Release tags → Run workflow**
   and choose `minor` or `major`.
4. Consuming repos pin `@v1` (recommended) or a full tag when freezing.

Bootstrap (no full tags yet): the first run creates `v1.0.0`, `v1.0`, and `v1`.

## Upgrade process for consumers

1. Read the changelog / PR history for the target tag.
2. Bump the `uses: ministryofjustice/hmpps-reporting-workflows/.github/workflows/...@vX`
   refs in the repo's thin caller workflow files.
3. Run the pipeline on a feature branch / PR (not `main`) and confirm the
   job graph, approval gates, and deploy behaviour are unchanged or changed
   as expected.
4. Merge to `main` only once the feature-branch run is green.
