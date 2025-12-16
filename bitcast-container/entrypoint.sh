#!/usr/bin/env bash
set -euo pipefail

ROLE="${BITCAST_ROLE:-validator}"
EXTRA_ARGS=("$@")

case "$ROLE" in
  validator)
    TARGET="neurons/validator.py"
    ;;
  miner)
    TARGET="neurons/miner.py"
    ;;
  *)
    echo "Unknown BITCAST_ROLE '$ROLE'. Expected 'validator' or 'miner'." >&2
    exit 1
    ;;
esac

if [[ ! -f "$TARGET" ]]; then
  echo "Unable to locate $TARGET inside the container." >&2
  exit 1
fi

exec python -u "$TARGET" "${EXTRA_ARGS[@]}"
