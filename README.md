# dotfiles

## installation

```
curl -sL https://raw.githubusercontent.com/jkeylu/dotfiles/master/install.sh | bash
wget -O - https://raw.githubusercontent.com/jkeylu/dotfiles/master/install.sh | bash
```

## Usage

- [bash](#bash)
- [brew](#brew)
- [code](#code)
- [frp](#frp)
- [fzf](#fzf)
- [git](#git)
- [glider](#glider)
- [iterm2](#iterm2)
- [kcpss](#kcpss)
- [kcptun](#kcptun)
- [nvm](#nvm)
- [pm2](#pm2)
- [ss](#ss)
- [tmux](#tmux)
- [vim](#vim)
- [zsh](#zsh)

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

### frp

```sh
dotfilebiu install frp
dotfilebiu run frp update
dotfilebiu service frp install [frpc|frps]
```

### fzf

```sh
dotfilebiu install fzf
```

### git

```sh
dotfilebiu install git
```

### glider

```sh
dotfilebiu install glider
dotfilebiu service glider install
```

### iterm2

```sh
dotfilebiu install iterm2
```

### kcpss

```sh
dotfilebiu service install kcpss client "#name" "#server" "#password"
dotfilebiu service install kcpss server "#name" "#server" "#password"
```

### kcptun

```sh
# install or update kcptun
dotfilebiu install kcptun
dotfilebiu service install kcptun client "#name" "#server_ip:#server_port:12948"
dotfilebiu service install kcptun server "#name" "#server_port:#target_port"
```

### nvm

```sh
dotfilebiu install nvm
dotfilebiu run nvm update
```

### pm2

```sh
dotfilebiu install pm2
```

### ss

```sh
dotfilebiu install ss
dotfilebiu service install ss local "#name" "#server" "#server_port" "#password"
dotfilebiu service install ss server "#name" "#server" "#server_port" "#password"
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
dotfilebiu run install wsl
```
