#!/usr/bin/env sh
# Refreshes the vendored catalog snapshot (spec §2.2). Run from the repo root;
# the release workflow runs this so every release ships a fresh snapshot.
set -e
BASE="https://raw.githubusercontent.com/ladyisatis/one-pace-metadata/refs/heads/v2/metadata"
curl -sfL "$BASE/arcs.json" -o assets/catalog/arcs.json
curl -sfL "$BASE/episodes.min.json" -o assets/catalog/episodes.json
curl -sfL "$BASE/descriptions.json" -o assets/catalog/descriptions.json
echo "Snapshot updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
