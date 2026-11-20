# Prompt "regular": the classic Ubuntu prompt — user@host in bold green and
# the path in blue.
# @desc: classic Ubuntu (green)

PS1_COLOR='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
PS1_PLAIN='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '

PROMPT_TITLE='\u@\h: \w'
