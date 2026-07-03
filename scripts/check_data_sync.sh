#!/usr/bin/env bash
#
# check_data_sync.sh — detect (and optionally fix) drift between the web
# backend's bundled data and this Flutter app's bundled assets.
#
# The Flutter app ships offline copies of station/landmark/line/affiliate data
# that originate in the web repo (norigo.app, ../project_meetup/data). Those
# files are regenerated on the web side over time; if we forget to refresh the
# Flutter copies, offline search / localization / affiliate deep-links silently
# go stale (this is exactly how line-translations.json drifted 219 vs 297).
#
# Usage:
#   scripts/check_data_sync.sh                 # report drift, exit 1 if any
#   scripts/check_data_sync.sh --sync          # copy web -> flutter for the
#                                              # allowlisted files, then report
#   WEB_DATA=/path/to/project_meetup/data scripts/check_data_sync.sh
#
# Only same-named JSON files present in BOTH trees are compared. Files with an
# intentionally different shape on each side (e.g. generated indexes) simply
# never share a name, so they are ignored automatically.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FL_DATA="$SCRIPT_DIR/../assets/data"
WEB_DATA="${WEB_DATA:-$SCRIPT_DIR/../../project_meetup/data}"

# Files that are safe to mirror verbatim from web -> flutter with --sync.
# (Same filename convention in this ecosystem implies the same schema; verified
# for these. Anything not listed is report-only, never auto-copied.)
SYNC_ALLOWLIST=(
  "landmarks-kanto.json"
  "landmarks-kansai.json"
  "landmarks-kyushu.json"
  "landmarks-seoul.json"
  "landmarks-busan.json"
  "line-translations.json"
  "station-jalan-codes.json"
  "station-codes.json"
  "agoda-area-ids.json"
)

SYNC=0
[[ "${1:-}" == "--sync" ]] && SYNC=1

if [[ ! -d "$WEB_DATA" ]]; then
  echo "ERROR: web data dir not found: $WEB_DATA" >&2
  echo "       set WEB_DATA=/path/to/project_meetup/data" >&2
  exit 2
fi

# Stable signature of a JSON file: (top-level entry count, content hash of the
# canonicalized JSON) so key ordering / whitespace don't create false drift.
sig() {
  python3 - "$1" <<'PY'
import json, sys, hashlib
try:
    d = json.load(open(sys.argv[1]))
except Exception as e:
    print(f"INVALID {e}")
    sys.exit(0)
n = len(d) if isinstance(d, (list, dict)) else 1
h = hashlib.sha256(json.dumps(d, sort_keys=True, ensure_ascii=False).encode()).hexdigest()[:12]
print(f"{n} {h}")
PY
}

in_allowlist() {
  local f="$1"
  for a in "${SYNC_ALLOWLIST[@]}"; do [[ "$a" == "$f" ]] && return 0; done
  return 1
}

drift=0
checked=0
synced=0

for fl in "$FL_DATA"/*.json; do
  name="$(basename "$fl")"
  web="$WEB_DATA/$name"
  [[ -f "$web" ]] || continue          # flutter-only asset (e.g. line-colors.json) — skip
  checked=$((checked + 1))

  fl_sig="$(sig "$fl")"
  web_sig="$(sig "$web")"

  if [[ "$fl_sig" == "$web_sig" ]]; then
    printf "  ok    %-28s %s\n" "$name" "$fl_sig"
    continue
  fi

  drift=$((drift + 1))
  printf "  DRIFT %-28s flutter=[%s]  web=[%s]\n" "$name" "$fl_sig" "$web_sig"

  if [[ "$SYNC" -eq 1 ]] && in_allowlist "$name"; then
    cp "$web" "$fl"
    synced=$((synced + 1))
    printf "        -> synced from web\n"
  elif [[ "$SYNC" -eq 1 ]]; then
    printf "        -> NOT in sync allowlist; copy/verify manually\n"
  fi
done

echo ""
echo "checked=$checked drift=$drift synced=$synced (web: $WEB_DATA)"

# After a --sync run, remaining drift is only the non-allowlisted files.
if [[ "$SYNC" -eq 1 ]]; then
  exit 0
fi
[[ "$drift" -eq 0 ]] && exit 0 || exit 1
