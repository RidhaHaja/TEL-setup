#!/usr/bin/env bash
tel_version=0.1
source ~/../usr/bin/tel-helpers
a=$(dirname $0)
#termux-setup-storage

spinpid=
function spin {
    while : ; do for X in '\u280B' '\u2819' '\u2839' '\u2838' '\u283C' '\u2834' '\u2826' '\u2827' '\u2807' '\u280F' ; do echo -en "\b$X" ; sleep 0.1 ; done ; done
      #while :; do for s in / - \\ \|; do printf "\r$s"; sleep .1; done; done
}

function start_spinner {
    set +m
    { spin & } 2>/dev/null
    spinpid=$!
}

function stop_spinner {
    { kill -9 $spinpid && wait; } 2>/dev/null
    set -m
    echo -en "\033[2K\r"
}

 ###################
if [ -z "$1" ]; then
	update_args="--setup"
else
	update_args="$1"
fi

# SHOULD CHECK HERE IF UPDATE IS NEEDED if so update then re run setup
UPDATE=false

if [ -f ~/.tel/.installed ]; then #set update var if finished installation was detected
	logf ".installed exists"
	error "TEL appears to already be installed. Continuing will replace all TEL files, you may also lose user configuration files. It is recommended to take a backup if you wish to continue. (command: tel-backup)"
	warn "Are you sure you want to continue? (y/N)"
	read -r user_reponse
	if [ "$user_reponse" != 'y' ] && [ "$user_reponse" != 'Y' ]; then
		error 'User exited the setup'
		exit 0
	fi
fi

check_connection

rm -rf ~/../etc/motd # avoids user prompt to maintain motd
rm -rf ~/../usr/etc/motd
log "Updating Termux packages..."
logf "apt-get upgrade"

if [  ! -d ~/.tel ]; then
pkg update -y 
termux-change-repo
fi

apt-get update -y && apt-get upgrade -y && logf "finished updating Termux packages" #print to screen as hotfix

log "Installing required packages"
log "This may take a while..."
logf "pkg install"
catch "$(pkg install git make curl wget nano tmux zsh termux-api sed figlet util-linux fzf fd bat links imagemagick openssh bc sl jq pup eza termimage ncurses-utils tsu man sl -y 2>&1)"
# maybe add: neofetch cronie moreutils, rmed tree cowsay
log "Installing python"
logf "python install"
catch "$(pkg install python -y 2>&1)" 

log "Installing python package manager"
logf "pip install"
which -a pip | grep -q '[n]ot found' && catch "$(curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py 2>&1)" && catch "$(python get-pip.py 2>&1)" && rm -f get-pip.py #skip reinstalling if pip exists

log "Installing python packages"
logf "pip pkgs install"
catch "$(pip install --user blessed pywal lolcat powerline-status 2>&1)" #removed psutil
logf "Finished packages download and installation"

#create required directories
mkdir -p ~/.termux
mkdir -p ~/.tel
mkdir -p ~/.config
mkdir -p ~/bin

# # # # ZSH setup # # #
log "Installing OMZ"
logf "ohmyzsh"
chsh -s zsh #set zsh default shell
rm -rf ~/../etc/motd 
rm -rf ~/.oh-my-zsh #incase setup is reran (must clone to empty dirs)
rm -rf ~/.tel/shell #incase setup is reran (must clone to empty dirs)
catch "$(git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh 2>&1)"
if [ -f ~/.zshrc ] ; then
	cp -f ~/.zshrc ~/.zshrc.bak #backup previous 
fi

cp -f ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

# Get updates!
log "Fetching updates..."
logf "running tel-update"
~/../usr/bin/tel-update $update_args

log "Installing shell plugins"
logf "cloning plugins"
catch "$(git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k 2>&1)"
#run p10k installer now
catch "$(sh ~/.oh-my-zsh/custom/themes/powerlevel10k/gitstatus/install 2>&1)"
catch "$(git clone --depth=1 https://github.com/securisec/fast-syntax-highlighting.git ~/.oh-my-zsh/plugins/fast-syntax-highlighting 2>&1)"
#catch "$(git clone --depth=1 https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/plugins/zsh-completions 2>&1)"
catch "$(git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions 2>&1)"
catch "$(git clone --depth=1 https://github.com/marlonrichert/zsh-autocomplete ~/.oh-my-zsh/plugins/zsh-autocomplete 2>&1)"
catch "$(git clone --depth=1 https://github.com/Aloxaf/fzf-tab ~/.oh-my-zsh/plugins/fzf-tab 2>&1)"
#catch "$(git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search ~/.tel/shell/plugins/zsh-history-substring-search 2>&1)"
#sed -i 's/robbyrussell/avit/g' ~/.zshrc
sed -i 's/robbyrussell/powerlevel10k\/powerlevel10k/g' ~/.zshrc
sed -i 's/plugins=(git)/plugins=(fzf-tab fancy-ctrl-z zsh-autosuggestions fast-syntax-highlighting)/g' ~/.zshrc 
#removed magic-enter common-aliases 

## Anisay ##
if [ ! -d ~/.tel/anisay ]; then
log "Installing anisay"
catch "$(git clone --depth=1 https://github.com/sealedjoy/anisay ~/.tel/anisay 2>&1)"
catch "$(cd ~/.tel/anisay && ~/.tel/anisay/install.sh 2>&1)"
fi
#
# # # insert TEL loading file into .zshrc # # # 
echo -e "	\n#|||||||||||||||#\n. ~/.tel/.telrc\n#|||||||||||||||#\n	" >> ~/.zshrc

if [ -f "$HOME/../usr/etc/motd_finished" ]; then
	#mv ~/../usr/etc/motd_finished ~/../usr/etc/motd #set final motd
	(rm -rf ~/../usr/etc/motd)
fi

fix_permissions
logf "fixing permissions"

# fix in tmux and aliases
log "fixing tmux and aliases"
sed -i 's/3.10/3.11/' ~/.tel/.tel_tmux.conf
sed -i 's/exa -/eza -/' ~/.aliases
####sed -i "s/ exa / eza /g" /data/data/com.termux/files/usr/bin/tel-setup && tel-setup

if [ "$UPDATE" = false ]; then
	echo -ne "$tel_version" > ~/.tel/.installed #mark setup finished
        log "Installation Complete"
else
        log "Update Complete"
fi
theme --alpha 99 > /dev/null 2>&1
log "complete"

 start_spinner
#...
if [ ! -f ~/.tel/Bunga ]; then
  if [ -f $a/Bunga ]; then
log "Installing Bunga to ~/.tel"
logf "Banner Bunga install"
cp $a/Bunga ~/.tel
sed -i "/ .*.Bunga/d" ~/.zshrc
echo -e "#\n. ~/.tel/Bunga\n#	" >> ~/.zshrc
echo -e 'alias clear=". ~/.tel/Bunga"' >> ~/.zshrc
echo -e 'alias reset=". ~/.tel/Bunga"' >> ~/.zshrc
echo -e 'alias tput clear=". ~/.tel/Bunga"' >> ~/.zshrc
echo -e 'alias tput reset="tput reset && . ~/.tel/Bunga"' >> ~/.zshrc
  fi
fi

if [ ! -f ~/.tel/precmd ]; then
  if [ -f $a/precmd ]; then
log "Installing precmd to ~/.tel"
logf "precmd install"
cp $a/precmd ~/.tel
chmod +x ~/.tel/precmd
sed -i "/ .*.precmd/d" ~/.zshrc
# TEL starts up with tmux env [true/false]
sed -i "s/\(export USE_TMUX=\\).*\(\#.*.\)/\1false \2/" ~/.tel/configs/userprefs.sh
sed -i "s/enabled/disabled/" ~/.tel/scripts/status_manager/.state
echo -e ". ~/.tel/precmd " >> ~/.zshrc
sleep 2
  fi
fi

if [ ! -f ~/.tel/Login.start ]; then
if [ -f $a/Login.start ]; then
log "Installing Login.start"
logf "Login.start install"
cp $a/Login.start ~/.tel
chmod +x ~/.tel/Login.start
sed -i "/ .*.Login.start/d" ~/.tel/.tel_profile
sed -i "/export PSWRD=.*/d" ~/.tel/configs/userprefs.sh
sed -i "/export LOCK=.*/d" ~/.tel/configs/userprefs.sh
echo -e "  ~/.tel/Login.start " >> ~/.tel/.tel_profile
echo -e " export PSWRD='' # your password " >> ~/.tel/configs/userprefs.sh
echo -e " export LOCK='false' # true / false - settings to enable application lock or not" >> ~/.tel/configs/userprefs.sh
sleep 2
  fi
fi

rm -f ~/tel-setup.sh
stop_spinner
logf "complete"
log "app will restart in 3 seconds!"
sleep 3
tel-restart
error 'Restart cannot be performed when app is not active on screen!'
log "press RETURN to retry"
read 
tel-restart
error 'Please run the command "tel-restart" manually'
exit 0