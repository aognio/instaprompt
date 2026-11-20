# Prompt "nix": inspired by the nix shell — the path in blue, a green ❯ and,
# inside a git repository, the current branch in red.
#
# Unlike the rest of instaprompt, this one forks once per prompt (git).
# @desc: nix style (❯ + git branch)

__instaprompt_nix_branch=""
if command -v git >/dev/null 2>&1; then
	__instaprompt_nix_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
	[ "$__instaprompt_nix_branch" = "HEAD" ] && __instaprompt_nix_branch=""
fi

PS1_COLOR='${debian_chroot:+($debian_chroot)}\[\033[01;34m\]\w\[\033[00m\]\[\033[01;32m\] ❯\[\033[00m\] '
PS1_PLAIN='${debian_chroot:+($debian_chroot)}\w ❯ '

if [ -n "$__instaprompt_nix_branch" ]; then
	PS1_COLOR="\[\033[01;31m\]${__instaprompt_nix_branch}\[\033[00m\] ${PS1_COLOR}"
	PS1_PLAIN="${__instaprompt_nix_branch} ${PS1_PLAIN}"
fi

PROMPT_TITLE='\w'
