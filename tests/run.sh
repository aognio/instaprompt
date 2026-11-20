#!/usr/bin/env bash
#
# instaprompt test suite.
#
#   bash tests/run.sh
#
# Every case runs in a fresh interactive bash with instaprompt loaded and a
# sandboxed state directory, so the suite never touches the real ~/.bashrc,
# ~/.bash_prompts or ~/.current_bash_prompt.

set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE="$REPO_DIR/instaprompt.sh"

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

USER_DIR="$SANDBOX/prompts"
STATE="$SANDBOX/current_prompt"
mkdir -p "$USER_DIR"

# Ubuntu's /etc/bash.bashrc prints a "sudo" hint to stdout when the home
# directory has no ~/.sudo_as_admin_successful marker. The sandbox home would
# trigger it on every shell, so silence it.
touch "$SANDBOX/.sudo_as_admin_successful"

pass=0
fail=0
skip=0

ok() {
	pass=$((pass + 1))
	printf '  ok    %s\n' "$1"
}

bad() {
	fail=$((fail + 1))
	printf '  FAIL  %s\n' "$1"
	printf '        %s\n' "$2"
}

check() { # name, actual, needle
	case "$2" in
	*"$3"*) ok "$1" ;;
	*) bad "$1" "expected to contain: $3
        actual: $2" ;;
	esac
}

check_eq() { # name, actual, expected
	if [ "$2" = "$3" ]; then
		ok "$1"
	else
		bad "$1" "expected: $3
        actual:   $2"
	fi
}

# Runs a snippet of bash inside a fresh interactive shell with instaprompt
# loaded. Extra arguments are passed as extra environment variables.
shell_run() {
	local errfile="$1"
	shift
	local -a extra_env=("$@")
	env -i \
		HOME="$SANDBOX" \
		TERM=xterm-256color \
		PATH="$PATH" \
		INSTAPROMPT_USER_DIR="$USER_DIR" \
		INSTAPROMPT_STATE="$STATE" \
		INSTAPROMPT_ENGINE="$ENGINE" \
		"${extra_env[@]+"${extra_env[@]}"}" \
		bash --rcfile "$ENGINE" -i 2>"$errfile"
}

shell() { shell_run /dev/null "$@"; }

# Same, but with the shell's stderr folded into the output.
shell_err() {
	local errfile="$SANDBOX/stderr"
	: >"$errfile"
	shell_run "$errfile" "$@"
	cat "$errfile"
}

# Renders the prompt with a given state value ("" removes the state file)
# and prints the resulting PS1.
ps1_for() {
	if [ -n "$1" ]; then
		printf '%s\n' "$1" >"$STATE"
	else
		rm -f "$STATE"
	fi
	printf 'printf "%%s" "$PS1"\n' | shell
}

section() {
	printf '\n%s\n' "$1"
}

# ---------------------------------------------------------------------------
section 'resolution: the value of the state file picks the prompt'
# ---------------------------------------------------------------------------
check 'no state file -> default.sh' "$(ps1_for "")" '\033[02;34m'
check 'state=regular -> regular.sh' "$(ps1_for regular)" '\033[01;34m'
check 'state=compact -> compact.sh' "$(ps1_for compact)" '\u@\h\[\033[02;34m\]:\w'
check 'state=minimal -> minimal.sh' "$(ps1_for minimal)" '\[\033[02;34m\]\w\[\033[00m\]'
check 'state=two-line -> two-line.sh' "$(ps1_for two-line)" '❯'
check 'state=clock -> clock.sh' "$(ps1_for clock)" '\A'
check 'state=powerline -> powerline.sh' "$(ps1_for powerline)" '\e[48;5;33m'
check 'state=nix -> nix.sh' "$(ps1_for nix)" '❯'

section 'resolution: anything unusable falls back to default.sh'
check 'unknown name -> default.sh' "$(ps1_for nope)" '\033[02;34m'
check 'path traversal -> default.sh' "$(ps1_for '../../../etc/passwd')" '\033[02;34m'
check 'absolute path -> default.sh' "$(ps1_for '/etc/passwd')" '\033[02;34m'
check 'empty value -> default.sh' "$(ps1_for ' ')" '\033[02;34m'
check 'shell metachars -> default.sh' "$(ps1_for 'x;rm -rf /')" '\033[02;34m'

section 'resolution: the state file is parsed leniently'
check 'trailing newline' "$(ps1_for regular)" '\033[01;34m'
check 'CRLF line ending' \
	"$(printf 'regular\r\n' >"$STATE"; printf 'printf "%%s" "$PS1"\n' | shell)" \
	'\033[01;34m'
check 'surrounding spaces' \
	"$(printf '  regular  \n' >"$STATE"; printf 'printf "%%s" "$PS1"\n' | shell)" \
	'\033[01;34m'

section 'resolution: the user directory wins over the shipped one'
# A user prompt with the same name as a shipped one must take precedence.
cat >"$USER_DIR/regular.sh" <<'EOF'
PS1_COLOR='\[\033[01;35m\]USER-OVERRIDE\[\033[00m\] '
EOF
check 'user copy overrides shipped regular.sh' "$(ps1_for regular)" 'USER-OVERRIDE'
rm -f "$USER_DIR/regular.sh"

cat >"$USER_DIR/mine.sh" <<'EOF'
PS1_COLOR='\[\033[01;35m\]MINE\[\033[00m\] '
EOF
check 'prompt that only exists in the user dir' "$(ps1_for mine)" 'MINE'
rm -f "$USER_DIR/mine.sh"

section 'utilities'
check_eq 'prompt-current prints the active name' \
	"$(printf 'regular\n' >"$STATE"; printf 'prompt-current\n' | shell)" 'regular'
check_eq 'prompt-current with no state file' \
	"$(rm -f "$STATE"; printf 'prompt-current\n' | shell)" '<default>'
check_eq 'prompt-use writes the state file' \
	"$(printf 'prompt-use compact >/dev/null\ncat "%s"\n' "$STATE" | shell)" 'compact'
check 'prompt-use reports the prompt it activated' \
	"$(printf 'prompt-use compact\n' | shell)" 'prompt: compact'
check 'prompt-use rejects an unknown prompt' \
	"$(printf 'prompt-use nope\n' | shell_err)" 'no such prompt'
check 'prompt-use rejects a traversal attempt' \
	"$(printf 'prompt-use ../../etc/passwd\n' | shell_err)" 'invalid prompt name'
check 'prompt-use with no arguments lists the prompts' \
	"$(printf 'prompt-use\n' | shell)" 'Prompts:'
check 'prompt-list marks the active prompt' \
	"$(printf 'regular\n' >"$STATE"; printf 'prompt-list\n' | shell)" '* regular'
check 'prompt-list shows the @desc of a prompt' \
	"$(printf 'prompt-list\n' | shell)" 'classic Ubuntu (green)'

section 'the PROMPT_COMMAND hook'
check_eq 'the hook is registered' \
	"$(printf 'printf "%%s" "$PROMPT_COMMAND"\n' | shell)" '__instaprompt_render'
check_eq 'the hook is registered exactly once' \
	"$(printf 'printf "%%s" "$PROMPT_COMMAND"\n' | shell |
		grep -o __instaprompt_render | wc -l | tr -d ' ')" '1'
check_eq 'sourcing twice does not duplicate the hook' \
	"$(printf '. "$INSTAPROMPT_ENGINE"\nprintf "%%s" "$PROMPT_COMMAND"\n' | shell |
		grep -o __instaprompt_render | wc -l | tr -d ' ')" '1'

printf 'PROMPT_COMMAND="true"\n. "%s"\n' "$ENGINE" >"$SANDBOX/rc.sh"
check_eq 'an existing PROMPT_COMMAND is preserved' \
	"$(bash --rcfile "$SANDBOX/rc.sh" -i 2>/dev/null <<< 'printf "%s" "$PROMPT_COMMAND"')" \
	'true;__instaprompt_render'

printf 'PROMPT_COMMAND=(true)\n. "%s"\n' "$ENGINE" >"$SANDBOX/rc2.sh"
check_eq 'the array form of PROMPT_COMMAND is supported' \
	"$(bash --rcfile "$SANDBOX/rc2.sh" -i 2>/dev/null <<< 'printf "%s" "${PROMPT_COMMAND[*]}"')" \
	'true __instaprompt_render'

section 'colour handling'
check 'INSTAPROMPT_COLOR=0 uses the plain prompt' \
	"$(printf 'regular\n' >"$STATE"; printf 'printf "%%s" "$PS1"\n' | shell INSTAPROMPT_COLOR=0)" \
	'\u@\h:\w\$ '
check 'TERM=dumb uses the plain prompt' \
	"$(printf 'regular\n' >"$STATE"
	   env -i HOME="$SANDBOX" TERM=dumb PATH="$PATH" \
	   INSTAPROMPT_USER_DIR="$USER_DIR" INSTAPROMPT_STATE="$STATE" \
	   bash --rcfile "$ENGINE" -i 2>/dev/null <<< 'printf "%s" "$PS1"')" \
	'\u@\h:\w\$ '
check 'the colour prompt is used by default' \
	"$(printf 'regular\n' >"$STATE"; printf 'printf "%%s" "$PS1"\n' | shell)" \
	'\033[01;32m'

section 'the exit status of the last command is visible to prompts'
check 'status.sh shows the failure marker' \
	"$(printf 'status\n' >"$STATE"
	   printf 'false\nprintf "%%s" "$PS1"\n' | shell)" '✗'
check 'status.sh shows the success marker' \
	"$(printf 'status\n' >"$STATE"
	   printf 'true\nprintf "%%s" "$PS1"\n' | shell)" '✓'

# ---------------------------------------------------------------------------
section 'integration: switching is immediate'
# ---------------------------------------------------------------------------
if command -v script >/dev/null 2>&1; then
	cat >"$SANDBOX/pty.sh" <<'EOF'
printf 'regular\n' >"$INSTAPROMPT_STATE"
bash --rcfile "$INSTAPROMPT_ENGINE" -i <<'EOS'
printf 'BEFORE=%s\n' "$([[ $PS1 == *02\;34m* ]] && echo default || echo regular)"
printf 'compact\n' >"$INSTAPROMPT_STATE"
printf 'AFTER=%s\n' "$([[ $PS1 == *02\;34m* ]] && echo compact || echo other)"
EOS
EOF
	out="$(INSTAPROMPT_USER_DIR="$USER_DIR" INSTAPROMPT_STATE="$STATE" \
		INSTAPROMPT_ENGINE="$ENGINE" script -qec "bash $SANDBOX/pty.sh" /dev/null 2>/dev/null)"
	check 'the prompt follows the state file on the next render' \
		"$out" 'BEFORE=regular'
	check 'the new prompt is picked up without restarting' \
		"$out" 'AFTER=compact'
else
	skip=$((skip + 1))
	printf '  skip  integration test (script(1) not available)\n'
fi

section 'performance: the render path spawns no subprocess'
if command -v strace >/dev/null 2>&1; then
	printf 'regular\n' >"$STATE"
	cat >"$SANDBOX/loop.sh" <<'EOF'
for ((i = 0; i < 50; i++)); do __instaprompt_render; done
EOF
	strace -f -e trace=clone,clone3,vfork -o "$SANDBOX/strace.txt" \
		env -i HOME="$SANDBOX" TERM=xterm-256color PATH="$PATH" \
		INSTAPROMPT_USER_DIR="$USER_DIR" INSTAPROMPT_STATE="$STATE" \
		bash --rcfile "$ENGINE" -i <"$SANDBOX/loop.sh" >/dev/null 2>&1
	forks="$(grep -cE 'clone|clone3|vfork' "$SANDBOX/strace.txt")"
	if [ "$forks" -lt 50 ]; then
		ok "50 renders cost $forks forks (one per render would be 50)"
	else
		bad '50 renders spawn a subprocess each' "forks: $forks"
	fi
else
	skip=$((skip + 1))
	printf '  skip  performance test (strace not available)\n'
fi

# ---------------------------------------------------------------------------
printf '\n%s passed, %s failed' "$pass" "$fail"
if [ "$skip" -gt 0 ]; then
	printf ', %s skipped' "$skip"
fi
printf '\n'
[ "$fail" -eq 0 ]
