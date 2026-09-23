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

### picker

`picker` reads one nonempty choice per line from standard input and prints the
choice to standard output. Use the arrow keys to move, Enter to choose, and Esc
to cancel. Add `--multi` to select several choices with Space and confirm with
Enter:

```sh
printf 'one\ntwo\nthree\n' | picker --prompt 'Choose one'
printf 'one\ntwo\nthree\n' | picker --multi --prompt 'Choose several'
```

It uses `fzf` when available and otherwise shows a built-in terminal menu.
Set `DOTFILES_PICKER_BUILTIN=1` to use the built-in menu, or `0` to require
`fzf` and disable the fallback. Leave it unset for automatic selection.

### jdev

`scripts/tools/jdev` watches a Spring Boot Maven or Gradle application, builds
an executable JAR, and restarts it when source, resources, or build files change.
Add `scripts/tools` to `PATH`, then run `jdev` from the application directory
without a configuration file, or create an optional template:

```sh
jdev
jdev init
jdev init --global
jdev --build-tool gradle --java-version 21
jdev jdk ls
jdev jdk ls-remote
jdev jdk install 21
jdev jdk install 8 --source adoptium
jdev jdk install 8 --no-verify-sha256
```

Configuration is read from `$HOME/.jdev.conf`, then the project `.jdev.conf`;
command line options take precedence. For a declared Java version, `jdev`
searches the JDK installations directly under `JDK_HOME` (or `$HOME/.jdks`
when unset), then checks `JAVA_HOME` and `PATH`. `jdev jdk ls` lists local JDKs;
`ls-remote` lists Eclipse Temurin LTS versions; `install <major>` downloads the
latest GA JDK from the Tsinghua mirror, verifies it against Adoptium's SHA-256
release metadata, shows download progress, and keeps older patch versions.
Use `--source adoptium` to download from the official release link, or
`--no-verify-sha256` to skip the checksum check. Gradle projects use `gradlew`
when present, followed by `GRADLE_HOME` and `PATH`. Use `jdev --help` for all
options.

### git

```sh
dotfilebiu install git
```

`git merged [branch]` lists local branches merged into `branch` (defaults to
`HEAD`), excluding the target branch. Use `git merged --clean [branch]` to
select one or more branches with `picker --multi`, review their local and remote
names, and confirm deletion. The remote branch comes from the local branch's upstream;
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

