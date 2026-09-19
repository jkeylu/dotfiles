# dotfiles

## Installation

```sh
curl -sL https://raw.githubusercontent.com/jkeylu/dotfiles/master/install.sh | bash
wget -O - https://raw.githubusercontent.com/jkeylu/dotfiles/master/install.sh | bash
```

## Usage

Run `dotfilebiu` without arguments to see the general help:

```sh
dotfilebiu
dotfilebiu list
dotfilebiu help nvm
```

The main commands are:

```text
dotfilebiu install <name>
dotfilebiu update
dotfilebiu run <name> <action> [args...]
dotfilebiu <name> <action> [args...]
```

`update` runs `git pull` in the dotfiles repository. `<name> <action>` is a
shortcut for `run <name> <action>`. `install` accepts exactly one component.
Use `list` to see available components and `help <name>` to see the actions
supported by one component.

Component actions are discovered automatically from functions declared in each
`opener/*.sh` after `util.sh` is loaded. Helper functions must start with `_`
so they remain private, and each opener ends with `run_cmd "$@"`.

### bash

```sh
dotfilebiu install bash
```

### brew

```sh
dotfilebiu install brew
```

### code

```sh
dotfilebiu install code
```

### fzf

```sh
dotfilebiu install fzf
```

### git

```sh
dotfilebiu install git
```

`git merged [branch]` lists local branches merged into `branch` (defaults to
`HEAD`), excluding the target branch. Use `git merged --clean [branch]` to
select one or more branches with `fzf`, review their local and remote names,
and confirm deletion. The remote branch comes from the local branch's upstream;
without an upstream, the command checks `origin` or the only configured remote
for a branch with the same name. Cleanup stops if a remote branch has a
different tip from its local branch.

### gvm

```sh
dotfilebiu install gvm
```

### iterm2

```sh
dotfilebiu install iterm2
```

### nvm

```sh
dotfilebiu install nvm
dotfilebiu run nvm update
dotfilebiu nvm update
```

### miniforge

```sh
dotfilebiu install miniforge
```

### tmux

```sh
dotfilebiu install tmux
```

### vim

```sh
dotfilebiu install vim
```

### zsh

```sh
dotfilebiu install zsh
```

