#!/usr/bin/env bash
# Usage: ./check_sbom.sh OWNER/REPO
# Downloads the repository SBOM from GitHub and prints how pub packages are related.
set -euo pipefail
repo="$1"
gh api "repos/$repo/dependency-graph/sbom" --jq .sbom > sbom.json
jq -r '
  (.relationships[] | select(.relationshipType=="DESCRIBES") | .relatedSpdxElement) as $root
  | (.packages | map({key: .SPDXID, value: "\(.name) \(.versionInfo)"}) | from_entries) as $n
  | (.packages | map(select(.externalRefs[0].referenceLocator | startswith("pkg:pub"))) | map(.SPDXID)) as $pub
  | "pub packages: \($pub | length)",
    "edges ROOT -> pub: \([.relationships[] | select(.spdxElementId==$root and (.relatedSpdxElement as $x | $pub | index($x)))] | length)",
    "edges pub -> pub:  \([.relationships[] | select((.spdxElementId as $x | $pub | index($x)) and (.relatedSpdxElement as $y | $pub | index($y)))] | length)",
    "",
    "pub packages linked from ROOT:",
    ([.relationships[] | select(.spdxElementId==$root and (.relatedSpdxElement as $x | $pub | index($x))) | "  " + $n[.relatedSpdxElement]] | sort[])
' sbom.json
