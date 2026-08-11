# Release Trust

The fork's manual release workflow publishes only Windows x64 archives and Android APKs to permanent GitHub Releases. It uses no repository secrets, external storage, update-index service, cloud deployment, or package-manager destination.

## Release Planning

Desktop and mobile keep independent semantic versions and tag sequences. `tool/release/release_plan.dart` detects changes for each product, and the workflow skips any product without changes. Stable cuts create normal GitHub Releases; release candidates create prereleases.

The workflow builds from the resolved target commit in a clean checkout. A dry run computes the next versions without building, tagging, or publishing.

## Windows

Windows builds run only on the native `windows-latest` x64 runner. The workflow verifies `RUNNER_ARCH` is `X64`, builds the Flutter desktop application and Rust sidecar, and validates the assembled helper and video runtimes before packaging.

Each desktop release contains:

- `alera-<version>-windows-x64.zip`
- `alera-<version>-windows-x64.zip.sha256`
- `alera-<version>-windows-x64.tar.gz`
- `alera-<version>-windows-x64.tar.gz.sha256`

The Windows bundle is not Authenticode signed. Windows SmartScreen therefore reports an unknown publisher. SHA-256 verification detects corruption but does not establish a publisher identity.

The repository retains Windows signing and updater tooling for local or upstream development, but the fork workflow does not read certificate secrets, generate desktop update descriptors, or publish R2 indexes.

## Android

The workflow builds release-mode Android APKs without `android/key.properties`. Gradle therefore uses the project's documented debug-key fallback. No signing or Firebase secrets are read, and no Firebase Dart definitions are injected.

Each mobile release contains universal, ARM64, ARMv7, and x86_64 APKs plus one SHA-256 file per APK. The workflow verifies every APK with `apksigner` before publication.

Debug signing has an important consequence: Android cannot update an installed application when the new APK uses a different signer. Users must uninstall before crossing signer identities. Firebase push registration is unavailable in these secret-free artifacts.

## Publication Checks

Build jobs first upload short-lived workflow artifacts so the publication job can verify the complete set. Before creating a GitHub Release, the publication job checks the expected file counts and validates every SHA-256 file. A failed or incomplete build cannot publish a partial product release.

The GitHub token has `contents: write` for release tags and permanent GitHub Releases plus `pull-requests: read` for release planning.

## Excluded Distribution Paths

The fork workflow does not publish:

- macOS or Linux application artifacts
- APT or RPM repositories
- Homebrew, Scoop, or Chocolatey manifests
- standalone cross-platform runtime sidecar archives
- signed desktop updater indexes
- cloud infrastructure or application deployments

The related source and packaging tools remain in the repository for local tests and upstream compatibility, but they are not part of the fork's GitHub Actions release path.
