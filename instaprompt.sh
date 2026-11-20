#!/usr/bin/env bash
#
# instaprompt.sh — a tiny, self-contained prompt manager for bash.
#
# Source it once, from ~/.bashrc:
#
#     [ -f "$HOME/.instaprompt/instaprompt.sh" ] && . "$HOME/.instaprompt/instaprompt.sh"
#
# How it works
# ------------
#   * A prompt is a *.sh file. Two directories are searched, in this order:
#       1. $INSTAPROMPT_USER_DIR  (default ~/.bash_prompts) — your own, wins
#       2. $INSTAPROMPT_DIR       (default <repo>/prompts)  — the shipped set
#   * The name of the active prompt lives in $INSTAPROMPT_STATE
#     (default ~/.current_bash_prompt): "regular", "compact", ...
#   * The state file is re-read before *every* prompt, so switching takes
#     effect on the very next command — no need to restart the terminal.
#
# Utilities: prompt-list, prompt-use <name>, prompt-current
#
# Licence: MIT

# ---------------------------------------------------------------------------
# Only meaningful in an interactive bash.
# ---------------------------------------------------------------------------
if [ -z "${BASH_VERSION:-}" ]; then
	return 0 2>/dev/null || exit 0
fi
case $- in
*i*) ;;
*) return 0 2>/dev/null || exit 0 ;;
esac

# ---------------------------------------------------------------------------
# Configuration. Every value can be overridden from the environment before
# sourcing this file.
# ---------------------------------------------------------------------------
__instaprompt_self="${BASH_SOURCE[0]:-$0}"
__instaprompt_repo="$(cd -- "$(dirname -- "$__instaprompt_self")" >/dev/null 2>&1 && pwd -P)"

: "${INSTAPROMPT_USER_DIR:=$HOME/.bash_prompts}"
: "${INSTAPROMPT_STATE:=$HOME/.current_bash_prompt}"
: "${INSTAPROMPT_DIR:=$__instaprompt_repo/prompts}"

# ---------------------------------------------------------------------------
# Colour support. Modern terminals are assumed to handle colour unless
# INSTAPROMPT_COLOR says otherwise.
# ---------------------------------------------------------------------------
__instaprompt_color_prompt=""
case "${INSTAPROMPT_COLOR:-auto}" in
1 | yes | always | force)
	__instaprompt_color_prompt=yes
	;;
0 | no | never)
	__instaprompt_color_prompt=""
	;;
*)
	case "$TERM" in
	'' | dumb) __instaprompt_color_prompt="" ;;
	*) __instaprompt_color_prompt=yes ;;
	esac
	;;
esac

# ---------------------------------------------------------------------------
# Keep the OSC 133 markers (vte / gnome-terminal) that PS1 may already carry.
# Captured once, at load time; PS1 is rebuilt from scratch on every render,
# so they are never duplicated.
# ---------------------------------------------------------------------------
__instaprompt_ps1_prefix=""
__instaprompt_ps1_suffix=""
case "$PS1" in
*'133;D;'*)
	__instaprompt_ps1_prefix='\[\e]133;D;$?\e\\\e]133;A\e\\\]'
	__instaprompt_ps1_suffix='\[\e]133;B\e\\\]'
	;;
esac

# Exit status of the last command, exposed to prompt files as
# __instaprompt_status. Captured before anything else runs, because every
# other command in this file would overwrite $?.
__instaprompt_status=0

# ---------------------------------------------------------------------------
# Helpers. All of them avoid subshells: they run on every single prompt.
# ---------------------------------------------------------------------------

# A prompt name must be a plain file name: no slashes, no path traversal.
__instaprompt_valid_name() {
	case "$1" in
	'' | *[!A-Za-z0-9_-]*) return 1 ;;
	*) return 0 ;;
	esac
}

# Locates "<name>.sh" in the user directory first, then in the shipped one.
# Leaves the path in __instaprompt_file.
__instaprompt_find() {
	local dir
	__instaprompt_file=""
	for dir in "$INSTAPROMPT_USER_DIR" "$INSTAPROMPT_DIR"; do
		[ -d "$dir" ] || continue
		if [ -r "$dir/$1.sh" ]; then
			__instaprompt_file="$dir/$1.sh"
			return 0
		fi
	done
	return 1
}

# Reads the active prompt name from the state file, into
# __instaprompt_state_name.
__instaprompt_read_state() {
	local name=""
	if [ -r "$INSTAPROMPT_STATE" ]; then
		IFS= read -r name <"$INSTAPROMPT_STATE" || :
	fi
	name="${name%$'\r'}"
	name="${name#"${name%%[![:space:]]*}"}"
	name="${name%"${name##*[![:space:]]}"}"
	case "$name" in
	'' | *[!A-Za-z0-9_-]*) name="" ;;
	esac
	__instaprompt_state_name="$name"
}

# Last resort, used when no prompt file can be found at all.
__instaprompt_fallback() {
	if [ "$__instaprompt_color_prompt" = yes ]; then
		PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
	else
		PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
	fi
	PROMPT_TITLE='\u@\h: \w'
}

# ---------------------------------------------------------------------------
# Renders the active prompt. Runs before every prompt.
# ---------------------------------------------------------------------------
__instaprompt_render() {
	__instaprompt_status=$?
	local file="" name=""

	__instaprompt_read_state
	name="$__instaprompt_state_name"

	# The value of the state file decides: if it matches the name of a
	# prompt file, that is the one to use; otherwise fall back to default.sh
	# and, failing that, to the built-in prompt.
	if [ -n "$name" ] && __instaprompt_find "$name"; then
		file="$__instaprompt_file"
	elif __instaprompt_find default; then
		file="$__instaprompt_file"
	fi

	unset PS1 PS1_COLOR PS1_PLAIN PROMPT_TITLE
	if [ -n "$file" ]; then
		# shellcheck source=/dev/null
		. "$file" || :
	fi

	if [ -z "${PS1:-}" ]; then
		if [ -n "${PS1_COLOR:-}" ]; then
			if [ "$__instaprompt_color_prompt" = yes ]; then
				PS1="$PS1_COLOR"
			else
				PS1="${PS1_PLAIN:-$PS1_COLOR}"
			fi
		else
			__instaprompt_fallback
		fi
	fi

	if [ -n "${PROMPT_TITLE:-}" ]; then
		PS1="\[\e]0;${debian_chroot:+($debian_chroot)}$PROMPT_TITLE\a\]$PS1"
	fi

	PS1="$__instaprompt_ps1_prefix$PS1$__instaprompt_ps1_suffix"
}

# ---------------------------------------------------------------------------
# Registers the render hook. It never clobbers an existing PROMPT_COMMAND and
# never registers twice.
# ---------------------------------------------------------------------------
__instaprompt_hook() {
	if [[ "$(declare -p PROMPT_COMMAND 2>&1)" == "declare -a"* ]]; then
		case " ${PROMPT_COMMAND[*]} " in
		*" __instaprompt_render "*) ;;
		*) PROMPT_COMMAND+=(__instaprompt_render) ;;
		esac
	else
		case "${PROMPT_COMMAND:-}" in
		*__instaprompt_render*) ;;
		"") PROMPT_COMMAND="__instaprompt_render" ;;
		*) PROMPT_COMMAND="${PROMPT_COMMAND%;};__instaprompt_render" ;;
		esac
	fi
}

__instaprompt_render
__instaprompt_hook

# ---------------------------------------------------------------------------
# prompt-list: list the available prompts, marking the active one.
# ---------------------------------------------------------------------------
prompt-list() {
	local dir file name desc cur seen=" "
	__instaprompt_read_state
	cur="$__instaprompt_state_name"
	printf 'Prompts:\n'
	for dir in "$INSTAPROMPT_USER_DIR" "$INSTAPROMPT_DIR"; do
		[ -d "$dir" ] || continue
		for file in "$dir"/*.sh; do
			[ -e "$file" ] || continue
			name="${file##*/}"
			name="${name%.sh}"
			case "$seen" in
			*" $name "*) continue ;;
			esac
			seen="$seen$name "
			desc="$(sed -n 's/^[[:space:]]*#[[:space:]]*@desc:[[:space:]]*//p' "$file" | head -1)"
			if [ "$name" = "$cur" ]; then
				printf '  * %-12s %s\n' "$name" "$desc"
			else
				printf '    %-12s %s\n' "$name" "$desc"
			fi
		done
	done
}

# ---------------------------------------------------------------------------
# prompt-use <name>: activate a prompt.
# ---------------------------------------------------------------------------
prompt-use() {
	local name="${1:-}"
	if [ -z "$name" ]; then
		prompt-list
		return 1
	fi
	if ! __instaprompt_valid_name "$name"; then
		printf 'prompt-use: invalid prompt name: %s\n' "$name" >&2
		return 1
	fi
	if ! __instaprompt_find "$name"; then
		printf 'prompt-use: no such prompt: %s\n' "$name" >&2
		return 1
	fi
	if ! printf '%s\n' "$name" >"$INSTAPROMPT_STATE"; then
		printf 'prompt-use: cannot write %s\n' "$INSTAPROMPT_STATE" >&2
		return 1
	fi
	__instaprompt_render
	printf 'prompt: %s\n' "$name"
}

# ---------------------------------------------------------------------------
# prompt-current: print the name of the active prompt.
# ---------------------------------------------------------------------------
prompt-current() {
	__instaprompt_read_state
	printf '%s\n' "${__instaprompt_state_name:-<default>}"
}
