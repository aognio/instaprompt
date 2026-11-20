#!/usr/bin/env bash
#
# Install instaprompt.
#
#   ./install.sh              copy the repo into ~/.instaprompt and add the
#                             one-liner to ~/.bashrc
#   ./install.sh --link       symlink instead of copy (the repo stays the
#                             source of truth)
#   ./install.sh --dry-run    show what would happen
#   ./install.sh --uninstall  remove the one-liner and the installed copy

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${INSTAPROMPT_INSTALL_DIR:-$HOME/.instaprompt}"
BASHRC="${BASHRC:-$HOME/.bashrc}"
MODE="copy"
DRY_RUN=0
UNINSTALL=0

usage() {
	sed -n '3,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
	case "$1" in
	--link) MODE="link" ;;
	--copy) MODE="copy" ;;
	--dry-run | -n) DRY_RUN=1 ;;
	--uninstall) UNINSTALL=1 ;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "unknown option: $1" >&2
		usage >&2
		exit 2
		;;
	esac
	shift
done

# The one-liner that goes into ~/.bashrc. It is a no-op when instaprompt is
# not installed, so it is safe to leave it there.
LINE="[ -f \"$INSTALL_DIR/instaprompt.sh\" ] && . \"$INSTALL_DIR/instaprompt.sh\""

has_line() {
	[ -f "$BASHRC" ] && grep -qxF "$LINE" "$BASHRC"
}

# A previous version of this setup may have had the prompt logic inline in
# ~/.bashrc. Both engines would fight over PS1, so say so.
warn_inline_block() {
	[ -f "$BASHRC" ] || return 0
	if grep -qE '__bashrc_prompt|\.adiestra_prompt|PS1=.*\\u@' "$BASHRC"; then
		echo
		echo "note: $BASHRC still contains a prompt block of its own."
		echo "      Remove it and keep only the instaprompt one-liner, otherwise"
		echo "      the two engines will fight over PS1."
	fi
}

if [ "$UNINSTALL" -eq 1 ]; then
	if [ -f "$BASHRC" ] && grep -qxF "$LINE" "$BASHRC"; then
		if [ "$DRY_RUN" -eq 1 ]; then
			echo "would remove the instaprompt line from $BASHRC"
		else
			tmp="$(mktemp)"
			grep -vxF "$LINE" "$BASHRC" >"$tmp" || true
			mv "$tmp" "$BASHRC"
			echo "removed the instaprompt line from $BASHRC"
		fi
	else
		echo "no instaprompt line in $BASHRC"
	fi

	if [ "$MODE" = "link" ] && [ -L "$INSTALL_DIR" ]; then
		if [ "$DRY_RUN" -eq 1 ]; then
			echo "would remove the symlink $INSTALL_DIR"
		else
			rm -f "$INSTALL_DIR"
			echo "removed the symlink $INSTALL_DIR"
		fi
	fi

	echo "done."
	exit 0
fi

# --- install the engine ----------------------------------------------------
if [ "$MODE" = "link" ]; then
	if [ "$DRY_RUN" -eq 1 ]; then
		echo "would link $INSTALL_DIR -> $REPO_DIR"
	else
		mkdir -p "$(dirname "$INSTALL_DIR")"
		rm -rf "$INSTALL_DIR"
		ln -s "$REPO_DIR" "$INSTALL_DIR"
		echo "linked  $INSTALL_DIR -> $REPO_DIR"
	fi
else
	if [ "$DRY_RUN" -eq 1 ]; then
		echo "would copy $REPO_DIR -> $INSTALL_DIR"
	else
		mkdir -p "$INSTALL_DIR"
		# Copy the engine, the prompts and the docs, but never the git
		# metadata: the installed copy is not a working tree.
		for item in instaprompt.sh prompts README.md README.es.md LICENSE; do
			[ -e "$REPO_DIR/$item" ] || continue
			rm -rf "${INSTALL_DIR:?}/$item"
			cp -R "$REPO_DIR/$item" "$INSTALL_DIR/$item"
		done
		echo "copied  $REPO_DIR -> $INSTALL_DIR"
	fi
fi

# --- add the one-liner to ~/.bashrc ----------------------------------------
if has_line; then
	echo "the one-liner is already in $BASHRC"
else
	if [ "$DRY_RUN" -eq 1 ]; then
		echo "would append to $BASHRC:"
		echo "    $LINE"
	else
		touch "$BASHRC"
		{
			echo
			echo "# instaprompt"
			echo "$LINE"
		} >>"$BASHRC"
		echo "added the one-liner to $BASHRC"
	fi
fi

warn_inline_block

echo
echo "done. open a new terminal (or run: source $BASHRC) and try:"
echo "    prompt-list"
echo "    prompt-use compact"
