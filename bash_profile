# User specific aliases and functions

export PATH=/usr/local/share/python:$PATH
export PATH=$PATH:~/developement/android/sdk:~/development/android/sdk/platform-tools:~/development/android/sdk/tools
export PATH="$(brew --prefix)/bin:$PATH"
export PATH=/usr/local/share/websploit:$PATH
export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export PATH=$GOPATH/bin:$PATH
export PATH=~/.composer/vendor/bin:$PATH
source $(brew --prefix php-version)/php-version.sh && php-version 7
export PATH="$(brew --prefix josegonzalez/php/php70)/bin:$PATH"

# Develop
export APPNAME_ENV=dev

#GIT
export GIT_PS1_SHOWUPSTREAM="auto"

function parse_git_branch {
   __git_ps1 "(%s)"
   # git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Powerline shell
function _update_ps1() {
    export PS1="$(~/powerline-shell.py $? 2> /dev/null)"
}

export PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"

# ssh-copy-id
function ssh-copy-id()
{
    cat ~/.ssh/id_rsa.pub | ssh $1 "mkdir ~/.ssh; cat >> ~/.ssh/authorized_keys"
}

# Show memory usage
function mem-usage()
{
    ps -amcwwwxo "command %mem %cpu" | grep -v grep | head -13
}

# Enable port forwarding
function port_forward() 
{
    sudo sysctl -w net.inet.ip.forwarding=1
    sudo sysctl -w net.inet.ip.fw.enable=1
}

BLACK="\[$(tput setaf 0)\\"
RED="\[$(tput setaf 1)\]"
GREEN="\[$(tput setaf 2)\]"
LIME="\[$(tput setaf 190)\]"
YELLOW="\[$(tput setaf 3)\]"
POWDER_BLUE="\[$(tput setaf 153)\]"
BLUE="\[$(tput setaf 4)\]"
MAGENTA="\[$(tput setaf 5)\]"
CYAN="\{$(tput setaf 6)\]"
WHITE="\[$(tput setaf 7)\]"
BRIGHT="\[$(tput bold)\]"
NORMAL="\[$(tput sgr0)\]"
UNDERLINE="\[$(tput smul)\]"

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

#vim
alias vim_install="vim +BundleInstall +qall"
alias vim="/usr/local/Cellar/vim/7.4.2109/bin/vim"
alias vi="/usr/local/Cellar/vim/7.4.2109/bin/vim"

#code
alias art="php artisan"
alias subl="sublime"
alias ij="open -b com.jetbrains.intellij"
alias cl="open -b com.jetbrains.clion"
alias show_hidden="defaults write com.apple.finder AppleShowAllFiles YES && killall -KILL Finder"
alias hide_hidden="defaults write com.apple.finder AppleShowAllFiles NO && killall -KILL Finder"
alias spoof_mac="sudo ifconfig en1 ether 00:f2:u3:c4:k5:s6"

# Hadoop
alias hstart="/usr/local/Cellar/hadoop/2.7.0/sbin/start-dfs.sh;/usr/local/Cellar/hadoop/2.7.0/sbin/start-yarn.sh"
alias hstop="/usr/local/Cellar/hadoop/2.7.0/sbin/stop-yarn.sh;/usr/local/Cellar/hadoop/2.7.0/sbin/stop-dfs.sh"

# Because
function tantrum()
{
  tput sc
  for i in {1..2}
  do
      if [ $((i%2)) -eq 0 ];
      then
	 printf "(╯°□°）╯︵┬─┬"
      else
	 printf "(°_°）┬─┬"
      fi
      sleep 1
      tput rc;tput el
  done
}

# Setting PATH for Python 2.7
# The orginal version is saved in .bash_profile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/2.7/bin:${PATH}"
export PATH

# Virtualenv/VirtualenvWrapper
export VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python3
source /usr/local/bin/virtualenvwrapper.sh

##
# Your previous /Users/tharmon/.bash_profile file was backed up as /Users/tharmon/.bash_profile.macports-saved_2016-03-16_at_21:27:37
##

# MacPorts Installer addition on 2016-03-16_at_21:27:37: adding an appropriate PATH variable for use with MacPorts.
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
# Finished adapting your PATH environment variable for use with MacPorts.

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
