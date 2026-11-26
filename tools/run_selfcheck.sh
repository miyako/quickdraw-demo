#!/usr/bin/env bash
# Headless acceptance run for QuickDraw Lab.
#
# tool4d cannot resolve dependency-manager github+tag entries, so this script
# copies the project into a scratch folder, replaces dependencies.json with an
# empty declaration, stages the component from Components/, and runs the same
# Lab_SelfCheck method the form's buttons call.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)

# TOOL4D overrides discovery. Otherwise prefer the build the evidence was
# recorded with, then a provisioned tool4d, then any installed 4D's tool4d.
if [ -z "${TOOL4D:-}" ]; then
  for candidate in "/Applications/4D 21 R5 (100175)/tool4d.app/Contents/MacOS/tool4d" \
      "$ROOT/tools/4dcli/tool4d.app/Contents/MacOS/tool4d" \
      /Applications/4D*/tool4d.app/Contents/MacOS/tool4d \
      /Applications/tool4d/tool4d.app/Contents/MacOS/tool4d; do
    if [ -x "$candidate" ]; then TOOL4D=$candidate; break; fi
  done
fi
if [ -z "${TOOL4D:-}" ] || [ ! -x "$TOOL4D" ]; then
  echo "tool4d not found; set TOOL4D=/path/to/tool4d" >&2
  exit 2
fi
SCRATCH=${SCRATCH:-$(mktemp -d)}
REPORT=$ROOT/Documentation/evidence/selfcheck.json

if [ ! -d "$ROOT/Components/quickdraw.4dbase" ]; then
  echo "Staging quickdraw.4dbase; pass a local copy as \$1 if you have one."
  "$ROOT/tools/stage_component.sh" "${1:?usage: run_selfcheck.sh [path/to/quickdraw.4dbase]}"
fi

rm -rf "$SCRATCH/Project" "$SCRATCH/Resources" "$SCRATCH/Components" "$SCRATCH/Output"
mkdir -p "$SCRATCH"
cp -R "$ROOT/Project" "$SCRATCH/Project"
cp -R "$ROOT/Resources" "$SCRATCH/Resources"
cp -R "$ROOT/Components" "$SCRATCH/Components"
printf '{"version":2100,"dependencies":{}}\n' > "$SCRATCH/Project/Sources/dependencies.json"

rm -f "$SCRATCH/Output/selfcheck.json"
"$TOOL4D" --project="$SCRATCH/Project/quickdraw-demo.4DProject" \
  --startup-method=Lab_SelfCheck --skip-onstartup --dataless

if [ ! -s "$SCRATCH/Output/selfcheck.json" ]; then
  echo "FAIL: no report written" >&2
  exit 1
fi
mkdir -p "$(dirname "$REPORT")"
cp "$SCRATCH/Output/selfcheck.json" "$REPORT"
python3 - "$REPORT" <<'PY'
import json, sys
report = json.load(open(sys.argv[1]))
print(f"{report['passed']}/{report['total']} checks passed")
for check in report["checks"]:
    print(("PASS " if check["ok"] else "FAIL "), check["name"], "|", check["detail"])
sys.exit(0 if report["passed"] == report["total"] else 1)
PY
