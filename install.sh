#!/usr/bin/env bash
# Install retail SDLC agents so they are available to every Cursor / Claude Code session.
#
# Usage:
#   ./install.sh                 # global install into ~/.claude/agents/
#   ./install.sh --project PATH  # install into a single project's .claude/agents/
#   ./install.sh --uninstall     # remove globally installed retail-* agents + retail _schemas/_templates
#   ./install.sh --symlink       # global install via symlinks (edits in repo flow live to ~/.claude/)

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
GLOBAL_AGENTS_DIR="$HOME/.claude/agents"
GLOBAL_SCHEMAS_DIR="$GLOBAL_AGENTS_DIR/_schemas/retail"
GLOBAL_TEMPLATES_DIR="$GLOBAL_AGENTS_DIR/_templates/retail"

MODE="global-copy"
PROJECT_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)  MODE="project";  PROJECT_DIR="${2:?--project needs a path}"; shift 2 ;;
    --symlink)  MODE="global-symlink"; shift ;;
    --uninstall) MODE="uninstall"; shift ;;
    -h|--help)
      sed -n '1,20p' "${BASH_SOURCE[0]}" | sed 's/^# //;s/^#//'
      exit 0 ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

install_global_copy() {
  mkdir -p "$GLOBAL_AGENTS_DIR" "$GLOBAL_SCHEMAS_DIR" "$GLOBAL_TEMPLATES_DIR"
  cp "$REPO_ROOT"/agents/*.md        "$GLOBAL_AGENTS_DIR/"
  cp "$REPO_ROOT"/schemas/*.json     "$GLOBAL_SCHEMAS_DIR/"
  cp "$REPO_ROOT"/templates/*.md     "$GLOBAL_TEMPLATES_DIR/"
  echo "Installed globally at: $GLOBAL_AGENTS_DIR"
}

install_global_symlink() {
  mkdir -p "$GLOBAL_AGENTS_DIR" "$(dirname "$GLOBAL_SCHEMAS_DIR")" "$(dirname "$GLOBAL_TEMPLATES_DIR")"
  for f in "$REPO_ROOT"/agents/*.md; do
    ln -sf "$f" "$GLOBAL_AGENTS_DIR/$(basename "$f")"
  done
  ln -sfn "$REPO_ROOT/schemas"   "$GLOBAL_SCHEMAS_DIR"
  ln -sfn "$REPO_ROOT/templates" "$GLOBAL_TEMPLATES_DIR"
  echo "Symlinked globally at: $GLOBAL_AGENTS_DIR (edits in repo reflect immediately)"
}

install_project() {
  [[ -d "$PROJECT_DIR" ]] || { echo "Not a dir: $PROJECT_DIR"; exit 1; }
  mkdir -p "$PROJECT_DIR/.claude/agents" \
           "$PROJECT_DIR/.claude/schemas/retail" \
           "$PROJECT_DIR/.claude/templates/retail"
  cp "$REPO_ROOT"/agents/*.md    "$PROJECT_DIR/.claude/agents/"
  cp "$REPO_ROOT"/schemas/*.json "$PROJECT_DIR/.claude/schemas/retail/"
  cp "$REPO_ROOT"/templates/*.md "$PROJECT_DIR/.claude/templates/retail/"
  echo "Installed in project: $PROJECT_DIR/.claude/"
}

uninstall_global() {
  rm -f "$GLOBAL_AGENTS_DIR"/retail-*.md || true
  rm -rf "$GLOBAL_SCHEMAS_DIR" "$GLOBAL_TEMPLATES_DIR" || true
  echo "Removed retail-* agents + retail schemas/templates from $GLOBAL_AGENTS_DIR"
}

case "$MODE" in
  global-copy)    install_global_copy ;;
  global-symlink) install_global_symlink ;;
  project)        install_project ;;
  uninstall)      uninstall_global ;;
esac

echo
echo "Installed agents:"
ls "$GLOBAL_AGENTS_DIR"/retail-*.md 2>/dev/null | xargs -n1 basename || echo "(none — uninstall mode or project mode)"
