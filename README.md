# instaprompt

A tiny prompt manager for bash. Clone the repo, add one line to `~/.bashrc`,
and switch prompts instantly.

[English](README.md) | [Español](README.es.md)

## Why

- **One line to install.** Clone, source, done.
- **Instant switching.** The name of the active prompt is re-read from a state
  file before *every* prompt, so `prompt-use compact` takes effect on the next
  command — no need to restart the terminal.
- **Prompts are just files.** A prompt is a `.sh` file with a handful of
  variables. Write your own in five lines.
- **No subprocesses.** The render path uses shell builtins only, so it costs
  nothing per prompt.

## Install

```sh
git clone https://github.com/aognio/instaprompt.git ~/.instaprompt
```

Then add this to the end of `~/.bashrc`:

```sh
[ -f "$HOME/.instaprompt/instaprompt.sh" ] && . "$HOME/.instaprompt/instaprompt.sh"
```

Open a new terminal (or `source ~/.bashrc`) and you are done.

The installer does both steps for you:

```sh
git clone https://github.com/aognio/instaprompt.git && cd instaprompt && ./install.sh
```

## Usage

```sh
prompt-list          # what is available, and which one is active
prompt-use compact   # switch
prompt-current       # print the active one
```

Switching is immediate: the next prompt you see is the new one.

## The shipped prompts

| Prompt | What it looks like |
|---|---|
| `default` | The fallback: green `user@host`, dim blue path |
| `regular` | The classic Ubuntu prompt |
| `minimal` | The path, and nothing else |
| `compact` | A dense one-liner |
| `two-line` | Identity on top, `❯` below |
| `clock` | The classic prompt with the time in front |
| `nix` | Path, `❯`, and the git branch |
| `status` | The marker turns red when the last command failed |
| `powerline` | Coloured segments with powerline separators |

## Writing your own prompt

Drop a file in `~/.bash_prompts/`:

```sh
# @desc: my prompt
PS1_COLOR='\[\033[01;36m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
PS1_PLAIN='\u@\h:\w\$ '
PROMPT_TITLE='\u@\h: \w'
```

| Variable | Meaning |
|---|---|
| `PS1_COLOR` | the prompt, with colour |
| `PS1_PLAIN` | the prompt, for terminals without colour |
| `PS1` | a complete prompt; it wins over the two above |
| `PROMPT_TITLE` | the terminal window/tab title |

Use **single quotes**: `\u`, `\w` and `\$` must expand when the prompt is
drawn, not when the file is read.

The `@desc:` comment is what `prompt-list` shows.

Prompt files are sourced right before the prompt is drawn, so they can look at
the shell state. `__instaprompt_status` holds the exit status of the last
command:

```sh
if [ "${__instaprompt_status:-0}" -ne 0 ]; then
    # the previous command failed
fi
```

Note that a prompt file that shells out (`git`, `docker`, ...) costs one fork
per prompt. The engine itself never does.

## How it works

The value of the state file picks the prompt:

```
~/.current_bash_prompt          ->  ~/.bash_prompts/<value>.sh
                                ->  ~/.instaprompt/prompts/<value>.sh
                                ->  ~/.instaprompt/prompts/default.sh
                                ->  a built-in green prompt
```

A prompt file in `~/.bash_prompts/` wins over one shipped with the repo, so
you can override any example without touching the repository.

The engine registers itself in `PROMPT_COMMAND`, which bash runs before every
prompt. That is what makes the switch instant. The hook:

- never clobbers an existing `PROMPT_COMMAND` — yours runs first;
- never registers twice, even if the file is sourced again;
- supports both the string and the array form of `PROMPT_COMMAND`.

## Configuration

Every value can be overridden from the environment before sourcing the file.

| Variable | Default | Meaning |
|---|---|---|
| `INSTAPROMPT_USER_DIR` | `~/.bash_prompts` | your prompts; they win |
| `INSTAPROMPT_DIR` | `<repo>/prompts` | the prompts shipped with the repo |
| `INSTAPROMPT_STATE` | `~/.current_bash_prompt` | the name of the active prompt |
| `INSTAPROMPT_COLOR` | `auto` | `auto`, `always` or `never` |

With `auto`, colour is used on every terminal that has a real `TERM`, and
dropped on `dumb` or empty ones.

## Migrating from an inline `~/.bashrc` block

If your `~/.bashrc` already contains a prompt block of its own, remove it and
keep only the instaprompt one-liner. Otherwise two engines write `PS1` on
every prompt and fight over it — the one registered last wins, so the symptom
is a prompt that flickers between the two.

The one-liner can live at the very end of `~/.bashrc`; it is a no-op when the
repository is not installed, so it is safe to commit it.

## Tests

```sh
bash tests/run.sh
```

The suite runs every case in a fresh interactive bash against a sandboxed
state directory, so it never touches your real `~/.bashrc`.

## Licence

MIT License - Copyright (c) 2026 Antonio Ognio — see [LICENSE](LICENSE).

Made with ❤️ from 🇵🇪. El Perú es clave 🔑.
