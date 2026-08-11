# AGENTS

## Scope

This file applies to GitHub metadata and GitHub Actions workflows.

## Workflow Policy

- Release jobs must be reproducible from a clean checkout.
- Build jobs must run on native runners for their platform.
- The retained workflows are `pr.yml`, `cloud.yml`, `landing.yml`, `merge-queue.yml`, `startup-performance.yml`, and `release-cut.yml`. The first five validate the repository; `release-cut.yml` is the only publishing workflow.
- The shared job prologue lives in `.github/actions/setup-flutter-workspace`. Flutter jobs must consume it rather than repeating setup steps inline. `actions/checkout` stays in the workflow because a local composite action cannot be resolved before checkout.
- Any job that builds the desktop app or runs Linux desktop integration tests must pass `rust: 'true'` to the shared setup action so the pinned Rust toolchain and Rust build cache are ready before native hooks run.
- Static analysis and root Flutter test jobs do not build the Linux desktop app and must pass `linux-toolchain: 'false'`. Test jobs must keep native asset setup and preflight enabled unless their package cannot invoke native asset hooks.
- Workflows must check out with `submodules: false` and initialize only required submodules through `.github/actions/init-required-submodules`. Initialization must stay recursive because `third_party/dart_terminal` contains nested submodules used by native asset cache keys.
- The native asset cache key must stay keyed only on runner OS, runner architecture, and hashed inputs. The Flutter version must remain pinned in the shared setup action.
- Rust compiler outputs use `sccache` through `.github/actions/setup-rust-sccache`. Workflows must remain functional without repository secrets or variables.
- Every workflow must declare an explicit `permissions` block. Test workflows use `contents: read`; the release workflow uses `contents: write` for tags and GitHub Releases plus `pull-requests: read` for product-scoped release planning.
- Pull request workflows must use a concurrency group keyed by `${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}` with `cancel-in-progress: true`. `release-cut.yml` uses `release-cut` with `cancel-in-progress: false` so an in-progress publication is not cancelled.
- The Flutter test job is sharded by file through `tool/ci/select_test_shard.dart`, never through `flutter test --total-shards/--shard-index`. `TEST_SHARDS`, matrix entries, and the coverage gate's `--expect-inputs` value must stay aligned.
- The desktop E2E job runs one `flutter test` invocation per file in `integration_test/`, never the directory.
- The Linux startup performance workflow remains a non-gating measurement. It runs without `--enforce-budget` and uses `continue-on-error` because shared xvfb runners are too noisy for a release gate.

## Release Policy

- `release-cut.yml` is a manual workflow that plans desktop and mobile independently, skips unchanged products, and preserves their separate version and tag sequences.
- Desktop publication builds only Windows x64 on `windows-latest`. It verifies the assembled runtime bundle, publishes ZIP and tar.gz archives, and includes a SHA-256 file for each archive.
- Mobile publication builds a universal Android APK plus ARM64, ARMv7, and x86_64 APKs. The workflow intentionally uses Gradle's debug-key fallback and must not read signing or Firebase secrets. Debug-signed APKs cannot update installations signed by another key.
- The publish job must verify artifact counts and SHA-256 files before creating permanent GitHub Releases.
- Stable releases are normal GitHub Releases. Release-candidate tags are marked as prereleases.
- The workflow does not publish macOS or Linux artifacts, desktop updater indexes, runtime sidecar archives, package-manager manifests, cloud deployments, or external storage.
- Do not add secret-backed signing or external deployment to the fork workflow without an explicit product decision and corresponding trust documentation.

## Issue And PR Policy

- Issue templates should collect platform details when behavior may differ across macOS, Windows, and Linux.
- Pull request templates should require validation notes, platform notes, and security or update-risk notes when relevant.
