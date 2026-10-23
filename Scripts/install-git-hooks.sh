#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
hooks_path="Scripts/git-hooks"

cd "$repo_root"

if [[ ! -x "$hooks_path/pre-commit" ]]; then
  chmod +x "$hooks_path/pre-commit"
fi

git config --local core.hooksPath "$hooks_path"

echo "Installed git hooks from $hooks_path"
echo "Active hook: pre-commit (string catalog normalization, SwiftFormat + SwiftLint on staged .swift files)"
