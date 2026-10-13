# Repository guidance

## Runtime contract

- This is a Linux Docker GitHub Action, not a Node project. The npm build in `README.md` belongs to the consuming application; this action deploys an already-built bundle.
- `action.yml` maps inputs to `ARVAN_*` environment variables; `entrypoint.sh` validates them, changes to `ARVAN_WORKDIR` if set, then runs the CLI. Keep metadata, script behavior, and documented inputs/outputs aligned.
- The `main.js` default lives only in `action.yml`. Direct Bash or Docker runs must set `ARVAN_API_KEY`, `ARVAN_APP`, and `ARVAN_FILE` explicitly; relative bundle paths resolve after the working-directory change.
- Keep authentication in the environment, never CLI arguments; retain token masking before CLI calls. Working-directory and bundle validation must precede even `arvan version`. See `SECURITY.md` for the token-handling contract.
- Preserve `pipefail`: deployment output is piped through `tee`, and CLI failure must still fail the action.

## Verification

Run from the repository root; these mirror the lint tools in `.github/workflows/ci.yml`:

```sh
shellcheck entrypoint.sh
docker run --rm -v "$PWD:/mnt" -w /mnt mvdan/shfmt:v3 --diff entrypoint.sh
docker run --rm -i hadolint/hadolint < Dockerfile
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:latest -color
npx --yes markdownlint-cli2 "**/*.md"
```

- Shell formatting uses tabs (`.editorconfig`); use shfmt's default indentation, not `-i 2`.
- For container changes: `docker build -t ar-ec-action:dev .`, then `docker run --rm --entrypoint /usr/local/bin/arvan ar-ec-action:dev version`. Builds download the pinned CLI and Debian packages, so require network access.
- CI builds the image and verifies the CLI install, missing-input enforcement, a missing-bundle failure, and a stubbed success-path run; it never contacts the deployment API. There is no separate unit-test runner.
- For an offline focused test, run `bash entrypoint.sh` with `ARVAN_BIN` pointing to an executable stub, dummy nonempty auth/app values, and an existing `ARVAN_FILE`. The stub must handle both `version` and `ec deploy`; emit `ID:`, `Status:`, and `Created At:` at the start of lines to exercise output parsing. The parser takes the last matching value; missing fields do not fail the script.
- Set `GITHUB_OUTPUT` and `GITHUB_STEP_SUMMARY` to temporary file paths to inspect reporting; both are optional outside GitHub Actions. An unstubbed success-path run performs a real deployment. See `CONTRIBUTING.md` for the container workspace mount example.

## Image and release gotchas

- `.dockerignore` allows only `entrypoint.sh`. Adding repository-sourced runtime files requires both an allowlist entry and a Dockerfile `COPY`.
- CLI upgrades require updating both `ARVAN_CLI_VERSION` ARG defaults in `Dockerfile` and both SHA-256 pins (`amd64` and `arm64`); use the release checksums, not locally guessed values. The final image needs CA certificates for API HTTPS.
- Follow `CONTRIBUTING.md` for Conventional Commits and changelog entries. Publishing a versioned GitHub release triggers `.github/workflows/release.yml` to force-move the floating major tag (such as `v1`).
