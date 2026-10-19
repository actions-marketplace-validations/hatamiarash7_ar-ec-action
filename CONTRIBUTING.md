# Contributing

Thanks for wanting to improve this action. This page describes how to get a change reviewed and merged.

## Repository layout

| File            | Purpose                                                             |
| --------------- | ------------------------------------------------------------------- |
| `action.yml`    | Action metadata: inputs, outputs and how the container is started   |
| `Dockerfile`    | Downloads and verifies the ArvanCloud CLI, builds the runtime image |
| `entrypoint.sh` | Validates the inputs, runs the deployment and reports results       |

## Requirements

- Docker
- [ShellCheck](https://www.shellcheck.net/)
- [shfmt](https://github.com/mvdan/sh) (or Docker, see below)
- Node.js 18+ (only used to run markdownlint through `npx`)

## Working on a change

Build the image:

```shell
docker build -t ar-ec-action:dev .
```

Run the action the way a runner would, by mounting a workspace and passing the inputs as environment variables:

```shell
workspace="$(mktemp -d)"
echo 'addEventListener("fetch", (e) => e.respondWith(new Response("ok")));' > "${workspace}/bundle.js"

docker run --rm \
  -v "${workspace}:/github/workspace" \
  -w /github/workspace \
  -e ARVAN_API_KEY="$ARVAN_API_KEY" \
  -e ARVAN_APP="my-app" \
  -e ARVAN_FILE="bundle.js" \
  ar-ec-action:dev
```

To exercise the reporting without touching the API, point `ARVAN_BIN` at a stub executable. The stub must answer `version` (used for the context log) and `ec deploy`, printing the same fields as the real CLI (`ID`, `Status`, `Created At`). Set `GITHUB_OUTPUT` and `GITHUB_STEP_SUMMARY` to file paths to capture the outputs and the job summary.

## Checks

The same checks run in CI, so it is worth running them before opening a pull request:

```shell
shellcheck entrypoint.sh
docker run --rm -v "$PWD:/mnt" -w /mnt mvdan/shfmt:v3 --diff entrypoint.sh
docker run --rm -i hadolint/hadolint < Dockerfile
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:latest -color
npx --yes markdownlint-cli2 "**/*.md"
```

## Upgrading the ArvanCloud CLI

The CLI version and its checksums are build arguments in the `Dockerfile`. To move to a new release:

1. Read the checksums from the release page, for example `https://git.arvancloud.ir/arvancloud/cli/-/releases/v0.4.0/downloads/arvan-cli-0.4.0-checksums.txt`.
2. Update `ARVAN_CLI_VERSION`, `ARVAN_CLI_SHA256_AMD64` and `ARVAN_CLI_SHA256_ARM64`. Both occurrences of the version (downloader and runtime stage) must match.
3. Rebuild and confirm `arvan version` reports the new version.

## Commits and releases

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org), for example `feat: add deployment tag input`. Notable changes belong in `CHANGELOG.md` under `Unreleased`.

Before publishing a release, move the `Unreleased` changes under the new version in `CHANGELOG.md` and bump `ACTION_VERSION` in the `Dockerfile`.

Publishing a GitHub release moves the floating major tag (`v1`) to that release, so consumers pinned to `@v1` pick the change up automatically.
