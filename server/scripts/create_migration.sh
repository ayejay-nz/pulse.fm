#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
migrations_dir="${script_dir}/../db/migrations"

timestamp="$(date +"%Y-%m-%d_%H%M%S")"
file="${migrations_dir}/${timestamp}.pgsql"

mkdir -p "${migrations_dir}"

if [ -e "${file}" ]; then
    echo "Migration already exists: ${file}" >&2
    exit 1
fi

cat >"${file}" <<'EOF'
BEGIN;

-- Write migration here

COMMIT;
EOF

echo "${file}"
