# Changelog

All notable changes to this repository are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-11-20

### New Features

- **`instaprompt.sh`** — the whole engine, in one file, with no dependencies
  beyond bash. Source it from `~/.bashrc` and it takes over the prompt.
  - The name of the active prompt is re-read from the state file before
    *every* prompt, so switching takes effect on the next command instead of
    the next shell.
  - Resolution order: `~/.bash_prompts/<value>.sh`, then the prompts shipped
    with the repo, then `default.sh`, then a built-in green prompt. A prompt
    in the user directory always wins over a shipped one with the same name.
  - The `PROMPT_COMMAND` hook never clobbers an existing value, never
    registers twice, and supports both the string and the array form.
  - The OSC 133 markers (vte / gnome-terminal) already present in `PS1` are
    preserved, and are not duplicated across renders.
  - The render path spawns no subprocess: reading the state file and locating
    the prompt file use builtins only. Measured with `strace`, fifty renders
    cost three forks — all of them from shell start-up.

- **`prompts/`** — nine example prompts, each one a small file: `default`,
  `regular`, `minimal`, `compact`, `two-line`, `clock`, `nix`, `status` and
  `powerline`. They exist to be read and copied, not to be used as-is.
  - `status` shows the exit status of the last command, exposed to prompt
    files as `__instaprompt_status`.

- **`prompt-list`, `prompt-use`, `prompt-current`** — the utilities. They
  refuse names that are not plain file names, so a prompt name can never
  escape the prompts directory.

- **`install.sh`** — installs the engine into `~/.instaprompt` and adds the
  one-liner to `~/.bashrc`. Idempotent, with `--link`, `--dry-run` and
  `--uninstall`.

- **`tests/run.sh`** — forty cases, each one in a fresh interactive bash
  against a sandboxed state directory. Covers resolution, fallbacks, the
  user-directory override, the utilities, the hook, colour handling, the
  exit-status feature, an end-to-end "switching is immediate" test through a
  pty, and a fork-count regression test.
