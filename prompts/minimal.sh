# Prompt "minimal": just the working directory and a dollar sign.
# @desc: minimal (path only)

PS1_COLOR='${debian_chroot:+($debian_chroot)}\[\033[02;34m\]\w\[\033[00m\]\$ '
PS1_PLAIN='${debian_chroot:+($debian_chroot)}\w\$ '

PROMPT_TITLE='\w'
