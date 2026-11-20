# Prompt "compact": everything crammed into one line, with the path dimmed.
# @desc: compact one-liner

PS1_COLOR='${debian_chroot:+($debian_chroot)}\u@\h\[\033[02;34m\]:\w\[\033[00m\]\$ '
PS1_PLAIN='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '

PROMPT_TITLE='\u@\h: \w'
