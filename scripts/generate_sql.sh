#!/usr/bin/env bash
set -euo pipefail

# Determine project root (the directory that contains this script's parent)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Paths
DBML_PATH="$PROJECT_ROOT/lib/domain/database/schema.dbml"
OUTPUT_DIR="$PROJECT_ROOT/lib/domain/database/sql"
OUTPUT_FILE="$OUTPUT_DIR/schema.sql"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

echo "Generating SQL from $DBML_PATH → $OUTPUT_FILE"
dbml2sql "$DBML_PATH" -o "$OUTPUT_FILE" -t sqlite
# TODO: make sure this echo only runs when the command succeeds
echo "✅ SQL generated at $OUTPUT_FILE"