# Prompt "two-line": the identity on the first line and the input marker on
# the second — the layout most modern shells use.
# @desc: two lines (❯ marker)

PS1_COLOR='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\n\[\033[01;32m\]❯\[\033[00m\] '
PS1_PLAIN='${debian_chroot:+($debian_chroot)}\u@\h:\w\n❯ '

PROMPT_TITLE='\u@\h: \w'
