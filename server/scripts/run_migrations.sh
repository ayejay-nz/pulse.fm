#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
migrations_dir="${script_dir}/../db/migrations"

read -r -a docker_cmd <<<"${DOCKER_CMD:-docker}"
db_container="${DB_CONTAINER:-pulsefm-postgres}"
db_user="${DB_USER:-postgres}"
db_name="${DB_NAME:-pulsefm}"

usage() {
    cat <<'EOF'
Usage:
  run_migrations.sh [--latest] [--all] [--count N] [--name FILE]

Options:
  --latest        Run the most recent migration (default)
  --all           Run all migrations in order
  --count N       Run the last N migrations in order
  --name FILE     Run a specific migration file (e.g. 2026-01-23_105519.pgsql)

Environment:
  DOCKER_CMD      Command to run docker (default: "docker"; e.g. "sudo docker")
  DB_CONTAINER    Container name (default: pulsefm-postgres)
  DB_USER         Database user (default: postgres)
  DB_NAME         Database name (default: pulsefm)
EOF
}

mode="latest"
name=""
count=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --latest)
            mode="latest"
            shift
            ;;
        --all)
            mode="all"
            shift
            ;;
        --count)
            mode="count"
            count="${2:-}"
            shift 2
            ;;
        --name)
            mode="name"
            name="${2:-}"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

if [[ ! -d "${migrations_dir}" ]]; then
    echo "Migrations directory not found: ${migrations_dir}" >&2
    exit 1
fi

mapfile -t all_files < <(ls -1 "${migrations_dir}"/*.pgsql 2>/dev/null | sort)

if [[ ${#all_files[@]} -eq 0 ]]; then
    echo "No migrations found in ${migrations_dir}" >&2
    exit 1
fi

files=()

case "${mode}" in
    latest)
        files=("${all_files[-1]}")
        ;;
    all)
        files=("${all_files[@]}")
        ;;
    count)
        if [[ -z "${count}" || ! "${count}" =~ ^[0-9]+$ || "${count}" -eq 0 ]]; then
            echo "Invalid count: ${count}" >&2
            exit 1
        fi
        if [[ "${count}" -gt "${#all_files[@]}" ]]; then
            echo "Count ${count} exceeds available migrations (${#all_files[@]})" >&2
            exit 1
        fi
        files=("${all_files[@]: -count}")
        ;;
    name)
        if [[ -z "${name}" ]]; then
            echo "Missing filename for --name" >&2
            exit 1
        fi
        target="${migrations_dir}/${name}"
        if [[ ! -f "${target}" ]]; then
            echo "Migration not found: ${target}" >&2
            exit 1
        fi
        files=("${target}")
        ;;
    *)
        echo "Unknown mode: ${mode}" >&2
        exit 1
        ;;
esac

for file in "${files[@]}"; do
    echo "Applying ${file}"
    "${docker_cmd[@]}" exec -i "${db_container}" \
        psql -U "${db_user}" -d "${db_name}" -v ON_ERROR_STOP=1 -f - < "${file}"
done
