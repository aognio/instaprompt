# Prompt "default": the fallback, used when the state file names a prompt
# that does not exist. Green user@host, dim blue path.
# @desc: fallback (green + dim blue)

PS1_COLOR='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[02;34m\]\w\[\033[00m\]\$ '
PS1_PLAIN='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '

PROMPT_TITLE='\u@\h: \w'
