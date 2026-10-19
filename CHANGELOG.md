# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- End-to-end CI check for a successful deployment, using a stubbed CLI so the deployment API is never contacted.
- Pull request template and sponsor links for the repository.

### Changed

- Fail with a clear error when the `arvan` CLI binary is missing or not executable.
- Copy `entrypoint.sh` with `--chmod` instead of a separate `chmod` layer.
- Parametrize the image version label (`ACTION_VERSION` build argument) and align it with the current release.

### Fixed

- Add the missing step `id` to the README workflow example so the documented outputs resolve.
- Point the local test instructions at a workspace directory that actually gets created.
- Document the markdownlint check that CI enforces alongside the other local checks.

## [1.0.3]

### Changed

- Update the logo and the header of the job summary.
- Improve documentation.

## [1.0.2]

### Changed

- Use H2 title for deployment summary.
- Update actions.

## [1.0.1]

### Added

- Upgrade `ArvanCloud CLI` to v0.4.0.
- `working-directory` input to resolve the bundle file against another directory.
- `id`, `status` and `created-at` outputs, plus a job summary for each deployment.
- Verification of the ArvanCloud CLI archive against a pinned SHA-256 checksum.
- Support for `arm64` runners.
- CI workflow running ShellCheck, shfmt, hadolint, actionlint and markdownlint.

### Changed

- Inputs are passed as environment variables instead of container arguments, so the API token no longer appears on the command line.
- The image is built in two stages, leaving no download tooling in the runtime image.
- Failures now produce a GitHub error annotation instead of a bare exit code.

## [1.0.0]

### Added

- Initial release: deploy a bundle file to ArvanCloud Edge Computing.

[1.0.3]: https://github.com/hatamiarash7/ar-ec-action/releases/tag/v1.0.3
[1.0.2]: https://github.com/hatamiarash7/ar-ec-action/releases/tag/v1.0.2
[1.0.1]: https://github.com/hatamiarash7/ar-ec-action/releases/tag/v1.0.1
[1.0.0]: https://github.com/hatamiarash7/ar-ec-action/releases/tag/v1.0.0
