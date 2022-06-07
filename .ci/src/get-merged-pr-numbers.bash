#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

readonly OUTPUT_DIR="$(mktemp -d)"

usage() {
  cat <<EOF >&2
Usage:
  cheat -h
  cheat [-v] --id <id> -- <commands>...
  cheat [-v] --id <id> --reveal
Execute commands but suppress errors with preserving the status.
Options:
-h, --help      Print this help and exit
-v, --verbose   Print script debug info
--id <id>       The id of the command sequence.
 --reveal       Remember the exit status of the id
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT

  rm -fr "${OUTPUT_DIR}"
}

initialize_colors() {
  NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

debug() {
  if [[ -z "${_VERBOSE_-}" ]]; then
    return 0
  fi

  msg "${PURPLE}$1${NOFORMAT}"
}

info() {
  msg "${GREEN}$1${NOFORMAT}"
}

warn() {
  msg "${YELLOW}$1${NOFORMAT}"
}

err() {
  msg "${RED}$1${NOFORMAT}"
}

die() {
  err "${1-}"
  exit "${2-1}"
}

parse_params() {
  baseline_tag=''
  head_branch=''

  _VERBOSE_=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) _VERBOSE_=1 ;;
    --no-color) NO_COLOR=1 ;;
    --baseline-tag)
      debug "--baseline-tag ${2-}"
      baseline_tag="${2-}"
      shift
      ;;
    --head-branch)
      debug "--head-branch ${2-}"
      head_branch="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac

    shift
  done

  [[ -z "$baseline_tag" ]] && die "Missing required parameter: --baseline-tag"
  [[ -z "$head_branch" ]] && die "Missing required parameter: --head-branch"

  return 0
}

initialize_colors
parse_params "$@"
setup_colors

readonly COMMIT_HASHES="$OUTPUT_DIR/commit_hashes.txt" PR_HEADS="$OUTPUT_DIR/pr_heads.txt"

readonly baseline="baseline-$(date +%s)" head="head-$(date +%s)"

info "Creating a local branch of $baseline_tag tag"

git fetch origin "refs/tags/$baseline_tag:refs/tags/$baseline_tag"
git branch "$baseline" "refs/tags/$baseline_tag" || warn "$baseline already exists"

info "Creating a local branch of $head_branch tag"

git fetch origin "$head_branch:$head"
git branch "$head" "origin/$head" || warn "$head already exists"

info "Fetch commits since the date of $baseline_tag"

git fetch origin --shallow-since "$(git log -1 --format=%cs "$baseline")"

info "Get all commits between $baseline..$head" 

git log --format=%H "$baseline".."$head" > "$COMMIT_HASHES"

if [[ "${_VERBOSE_-}" == "1" ]]; then
  cat < "$COMMIT_HASHES" 1>&2
fi

info "Get all PR's head refs"

git ls-remote origin 'pull/*/head' > "$PR_HEADS"

if [[ "${_VERBOSE_-}" == "1" ]]; then
  cat < "$PR_HEADS" 1>&2
fi

pr_nums=()

while read -r commit_hash pr_ref; do
  pr_num="$(echo "$pr_ref" | sed -e 's/^.*\/\([0-9]*\)\/.*$/\1/g')"

  if grep "$commit_hash" "$COMMIT_HASHES" >/dev/null 2>&1; then
    pr_nums+=("$pr_num")
  fi
done < "$PR_HEADS"

echo "${pr_nums[@]}" | tr " " "\n"
