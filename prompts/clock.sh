# Prompt "clock": the classic Ubuntu prompt with the time in front of it.
# @desc: with the time (HH:MM)

PS1_COLOR='${debian_chroot:+($debian_chroot)}\[\033[02;37m\]\A\[\033[00m\] \[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
PS1_PLAIN='${debian_chroot:+($debian_chroot)}\A \u@\h:\w\$ '

PROMPT_TITLE='\u@\h: \w'
