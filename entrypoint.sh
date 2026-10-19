#!/usr/bin/env bash
#
# Entrypoint of the Arvancloud Edge Computing Action.
#
# Every input is passed as an environment variable by action.yml so that the
# API token never appears in the container's command line:
#
#   ARVAN_API_KEY  Arvancloud API token                        (required)
#   ARVAN_APP      Edge Computing application name             (required)
#   ARVAN_FILE     Bundle file to deploy                       (required)
#   ARVAN_WORKDIR  Directory ARVAN_FILE is resolved against    (optional)

set -euo pipefail

readonly ARVAN_BIN="${ARVAN_BIN:-/usr/local/bin/arvan}"

API_KEY="${ARVAN_API_KEY:-}"
APP="${ARVAN_APP:-}"
FILE="${ARVAN_FILE:-}"
WORKDIR="${ARVAN_WORKDIR:-}"

info() {
	printf ' -----> %s\n' "$1"
}

fail() {
	printf '::error::%s\n' "$1" >&2
	exit 1
}

group() {
	printf '::group::%s\n' "$1"
}

endgroup() {
	printf '::endgroup::\n'
}

# Appends a key/value pair to the step's output file, when running on a runner.
set_output() {
	[ -n "${GITHUB_OUTPUT:-}" ] || return 0
	printf '%s=%s\n' "$1" "$2" >>"$GITHUB_OUTPUT"
}

write_summary() {
	[ -n "${GITHUB_STEP_SUMMARY:-}" ] || return 0
	cat >>"$GITHUB_STEP_SUMMARY" <<-EOF
		## Arvancloud Edge Computing deployment :rocket:

		| Field | Value |
		| --- | --- |
		| Application | \`${APP}\` |
		| Bundle | \`${FILE}\` |
		| Deployment ID | \`${DEPLOYMENT_ID:-unknown}\` |
		| Status | \`${DEPLOYMENT_STATUS:-unknown}\` |
	EOF
}

print_header() {
	printf '%s\n' "          ++++                                                                 "
	printf '%s\n' "         +++++++                                                               "
	printf '%s\n' "          +++++++          _                               _                 _ "
	printf '%s\n' "           +++++++        / \   _ ____   ____ _ _ __   ___| | ___  _   _  __| |"
	printf '%s\n' "            +++++++      / _ \ | '__\ \ / / _\` | '_ \ / __| |/ _ \| | | |/ _\` |"
	printf '%s\n' " +++++       +++++++    / ___ \| |   \ V / (_| | | | | (__| | (_) | |_| | (_| |"
	printf '%s\n' "+++++++       +++++++  /_/   \_\_|    \_/ \__,_|_| |_|\___|_|\___/ \__,_|\__,_|"
	printf '%s\n' " +++++          ++++                                                           "
	printf '\n'
}

validate_inputs() {
	[ -n "$API_KEY" ] || fail "The 'auth' input is required. Pass your ArvanCloud API token, e.g. \${{ secrets.ARVAN_API_KEY }}."
	[ -n "$APP" ] || fail "The 'app' input is required. Set it to your Edge Computing application name."
	[ -n "$FILE" ] || fail "The 'file' input is required. Set it to the bundle file you want to deploy."

	# The token is a secret for the workflow, but not necessarily for a
	# forked/reusable caller, so mask it defensively.
	printf '::add-mask::%s\n' "$API_KEY"

	if [ -n "$WORKDIR" ]; then
		[ -d "$WORKDIR" ] || fail "Working directory '${WORKDIR}' does not exist."
		cd "$WORKDIR"
	fi

	if [ ! -f "$FILE" ]; then
		fail "Bundle file '${FILE}' was not found in '$(pwd)'. Make sure the repository is checked out and the file is built before this step."
	fi
}

print_context() {
	group "Deployment context"
	printf 'Application    : %s\n' "$APP"
	printf 'Bundle file    : %s\n' "$FILE"
	printf 'Bundle size    : %s bytes\n' "$(wc -c <"$FILE" | tr -d ' ')"
	printf 'Directory      : %s\n' "$(pwd)"
	printf 'CLI version    : %s\n' "$("$ARVAN_BIN" version)"
	endgroup
}

# Reads the last "<field>: <value>" line out of the CLI output.
extract_field() {
	sed -n "s/^${1}:[[:space:]]*//p" "$LOG_FILE" | tail -n 1 | tr -d '\r'
}

deploy() {
	local -a command=("$ARVAN_BIN" ec deploy --file "$FILE" "$APP")

	info "Deploying '${APP}' to ArvanCloud Edge Computing"

	if ! ARVAN_API_KEY="$API_KEY" "${command[@]}" 2>&1 | tee "$LOG_FILE"; then
		# The CLI stays quiet when the API rejects the credentials.
		if ! grep -qi '^error' "$LOG_FILE"; then
			printf '::warning::The CLI reported no reason. This usually means the API token is invalid, expired, or has no access to application "%s".\n' "$APP"
		fi
		fail "Deployment of '${APP}' failed. See the CLI output above for details."
	fi

	DEPLOYMENT_ID="$(extract_field "ID")"
	DEPLOYMENT_STATUS="$(extract_field "Status")"
	DEPLOYMENT_CREATED_AT="$(extract_field "Created At")"

	set_output "id" "$DEPLOYMENT_ID"
	set_output "status" "$DEPLOYMENT_STATUS"
	set_output "created-at" "$DEPLOYMENT_CREATED_AT"

	info "Deployment finished with status '${DEPLOYMENT_STATUS:-unknown}'"
}

main() {
	LOG_FILE="$(mktemp)"
	# shellcheck disable=SC2064 # LOG_FILE must be expanded now, not on exit.
	trap "rm -f '${LOG_FILE}'" EXIT

	DEPLOYMENT_ID=""
	DEPLOYMENT_STATUS=""
	DEPLOYMENT_CREATED_AT=""

	print_header
	validate_inputs
	[ -x "$ARVAN_BIN" ] || fail "The ArvanCloud CLI was not found or is not executable at '${ARVAN_BIN}'. The image may be broken, or ARVAN_BIN points to the wrong file."
	print_context
	deploy
	write_summary
}

main "$@"
