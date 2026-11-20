# Prompt "powerline": the host and the path on coloured segments, separated by
# the usual powerline glyphs.
# @desc: powerline segments

PS1_COLOR='${debian_chroot:+($debian_chroot)}\[\e[48;5;236m\]\[\e[38;5;15m\] \u@\h \[\e[0m\]\[\e[38;5;236m\]\[\e[0m\]\[\e[48;5;33m\]\[\e[38;5;15m\] \w \[\e[0m\]\[\e[38;5;33m\]\[\e[0m\] '
PS1_PLAIN='${debian_chroot:+($debian_chroot)}\u@\h: \w $ '

PROMPT_TITLE='\u@\h: \w'
