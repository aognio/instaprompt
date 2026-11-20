# Prompt "status": like the classic Ubuntu one, but the marker turns red when
# the last command failed.
#
# Prompt files are sourced right before the prompt is drawn, so they can look
# at the shell state. __instaprompt_status holds the exit status of the last
# command.
# @desc: red marker when the last command failed

if [ "${__instaprompt_status:-0}" -ne 0 ]; then
	PS1_COLOR='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[01;31m\] ✗\[\033[00m\]\$ '
	PS1_PLAIN='${debian_chroot:+($debian_chroot)}\u@\h:\w ✗$ '
else
	PS1_COLOR='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[01;32m\] ✓\[\033[00m\]\$ '
	PS1_PLAIN='${debian_chroot:+($debian_chroot)}\u@\h:\w ✓$ '
fi

PROMPT_TITLE='\u@\h: \w'
