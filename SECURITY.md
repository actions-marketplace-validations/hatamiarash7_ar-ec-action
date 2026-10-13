# Security policy

## Scope

This policy covers the `ar-ec-action` repository: the action metadata, the Docker image and the entrypoint script. Problems with the ArvanCloud platform or the `arvan` CLI itself should be reported to ArvanCloud instead.

## Supported versions

Fixes are released for the latest major tag only.

| Version | Supported |
| ------- | --------- |
| `v1`    | Yes       |
| Older   | No        |

## Reporting a vulnerability

Please do not open a public issue for a security problem. Report it through [GitHub's private advisory form](https://github.com/hatamiarash7/ar-ec-action/security/advisories/new), or by email to <hatamiarash7@gmail.com>. You can expect an initial reply within a few days.

## How this action handles your token

- The token is passed to the container as an environment variable, never as a command line argument, so it does not appear in process lists.
- The entrypoint emits an `::add-mask::` command for the token, so the runner redacts it from the logs even when the value did not come from a secret.
- The token is only forwarded to the `arvan` CLI process and is never written to disk, to the step outputs or to the job summary.

Always store the token in an [encrypted secret](https://docs.github.com/actions/security-guides/encrypted-secrets) and never in the workflow file.

## Supply chain

The `arvan` CLI is downloaded during the image build and checked against a SHA-256 checksum pinned in the `Dockerfile`. A build fails if the published archive no longer matches.
