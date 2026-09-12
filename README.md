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
dotfilebiu uninstall <name>
dotfilebiu run <name> <action> [args...]
```

`install` and `uninstall` accept exactly one component. Use `list` to see
available components and `help <name>` to see the actions supported by one
component.

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
dotfilebiu uninstall brew
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

