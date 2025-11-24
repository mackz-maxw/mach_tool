#!/usr/bin/env bash
# robust_top_ips.sh - 统计 access.log 中指定日期并返回 top N IP（示例脚本）
# Usage: ./robust_top_ips.sh -f access.log -n 5
# Requires: bash, awk, sort, head

set -euo pipefail

prog_name=$(basename "$0")
topN=5
logfile=""
verbose=0

usage() {
  cat <<EOF
Usage: $prog_name -f <access.log> [-n <topN>] [-d <date>] [-v]
  -f FILE   access log file (required)
  -n N      top N IPs (default: 5)
  -d DATE   date in format DD/Mon/YYYY (default: today)
  -v        verbose logging
  -h        show this help
EOF
}

log() {
  local level=$1; shift
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "[$ts] [$level] $*"
}

debug() {
  if [[ "${verbose:-0}" -eq 1 ]]; then
    log "DEBUG" "$@"
  fi
}
info()  { log "INFO"  "$@"; }
error() { log "ERROR" "$@" >&2; }

# parse args
while getopts ":f:n:d:vh" opt; do
  case "$opt" in
    f) logfile=$OPTARG ;;
    n) topN=$OPTARG ;;
    d) target_date=$OPTARG ;;
    v) verbose=1 ;;
    h) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

if [[ -z "${logfile:-}" ]]; then
  error "access log file must be provided with -f"
  usage
  exit 2
fi

# default date = today in format 10/Oct/2000
target_date=${target_date:-$(date +%d/%b/%Y)}
debug "logfile=$logfile, topN=$topN, date=$target_date"

# temp file and cleanup
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT
# info "Wrote results to $tmpfile"

# Validate logfile readable
if [[ ! -r "$logfile" ]]; then
  error "Cannot read logfile: $logfile"
  exit 3
fi

# Main processing: use awk to filter and count (single-process)
# Note: assumes common/combined log where $4 contains date like [10/Oct/2000:...]
awk -v d="$target_date" '
  $4 ~ d && $9 == 200 { counts[$1]++ }
  END {
    for (ip in counts) print counts[ip], ip
  }
' "$logfile" | sort -nr | head -n "$topN" | tee "$tmpfile"

exit 0
