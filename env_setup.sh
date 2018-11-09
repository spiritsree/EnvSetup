#!/usr/bin/env bash

########################################################################################################
#                                        Enviroment Setup                                              #
########################################################################################################

# Global Vars
PKG_INSTALLS_COMMON='bash-completion zsh zsh-completions watch tree git tig screen tmux ruby jq yq python3 pip3 htop yamllint jsonlint shellcheck jid colordiff'
PKG_INSTALLS_WORK='docker docker-compose kubernetes-helm kubernetes-cli kops vagrant virtualbox terraform'
PKG_INSTALLS_PERSONAL='google-chrome utorrent atom sublime-text vlc firefox 4k-video-downloader 4k-stogram 4k-youtube-to-mp3 4k-video-to-mp3 dash'
PIP_INSTALLS='virtualenv awscli boto3'
APP_PROFILES='.vimrc .gvimrc .tmux.conf .tmux-osx.conf .gemrc .tigrc .screenrc .irbrc .inputrc .gitconfig .gitignore .yamllint'

PROFILES_DIR="./profiles"
THEMES_DIR="./themes"
BIN_DIR="./bin"
ARG_DEBUG=0
ARG_FORCE=0
ARG_ENV='WORK'
SCRIPT_NAME="$( basename "${BASH_SOURCE[0]}" )"
RED='\033[0;31m'      # Red
NC='\033[0m'          # Color Reset


# Usage help
_usage() {
    if [[ ! -z $@ ]]; then
        size=`echo $@ | wc -c`
        length=$((${size} + 7 + 5))
        printf "#%.0s" {1..${length}}
        echo -e "\n# ${RED}ERROR:${NC} $@"
        printf '#%.0s' {1..${length}}
        echo
    fi
    echo 'Sets up the work/personal environment.'
    echo
    echo 'Usage:'
    echo "    ${SCRIPT_NAME} [-h|--help] [-f|--force] [-d|--debug] [-e|--env <work|personal>]"
    echo
    echo 'Arguments:'
    echo '    -h|--help                     Print usage'
    echo '    -d|--debug                    Debug Messages'
    echo '    -f|--force                    Force copy profiles'
    echo '    -e|--env <env>                Environment [work|personal]. Defaults to work'
    echo
    echo 'Examples:'
    echo "    ${SCRIPT_NAME}"
    echo "    ${SCRIPT_NAME} -e personal     (for personal env setup)"
    echo
}

# Get Options
_getOptions() {
    optspec=":hfde:-:"
    while getopts "$optspec" opt; do
        case $opt in
            -)
                case "${OPTARG}" in
                    debug)
                        ARG_DEBUG=1
                        ;;
                    env)
                        ARG_ENV="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                        if [ -z "${ARG_ENV}" ]; then
                            _usage "Need to specify an environment for --env"
                            exit 1
                        fi
                        ;;
                    help)
                        _usage
                        exit 0
                        ;;
                    force)
                        ARG_FORCE=1
                        ;;
                    *)
                        if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                            _usage "Unknown option --${OPTARG}"
                            exit 1
                        fi
                        ;;
                esac;;
            h)
                _usage
                exit 0
                ;;
            f)
                ARG_FORCE=1
                ;;
            d)
                ARG_DEBUG=1
                ;;
            e)
                ARG_ENV="${OPTARG}"
                ;;
            \?)
                _usage "Invalid option: -$OPTARG"
                exit 1
                ;;
            :)
                _usage "Option -$OPTARG requires an argument."
                exit 1
                ;;
        esac
    done
}

# Detect Platform, Supports Mac OS, Linux, Ubuntu
_getPlatform() {
    local platform=''

    if [ $(uname) == 'Darwin' ]; then
        platform='MacOS'
    elif [[ $(uname) == 'Linux' ]] && [[ -f '/etc/lsb-release' ]]; then
        platform='Ubuntu'
    elif [[ $(uname) == 'Linux' ]]; then
        platform='Linux'
    fi

    echo "${platform}"
}

# runs the given command as root (detects if we are root already)
_runAsRoot() {
    local CMD="$*"

    if [[ $EUID -ne 0 ]]; then
        CMD="sudo $CMD"
    fi

    $CMD
}

# Capitalise
_capitalize() {
    local in=$1
    local out=$(echo ${in} | tr '[a-z]' '[A-Z]')
    echo "${out}"
}

# Ask
_ask() {
    local in=$@
    echo -n "${in}? "
    read val
    local out=$(_capitalize ${val})
    if [[ ${out} == 'Y' ]] || [[ ${out} == 'YES' ]]; then
        return 1
    else
        return 0
    fi
}

# Base Setup returns installer
_baseSetup() {
    local platform=$1
    if [[ ${platform} == 'MacOS' ]]; then
        # Ruby (MAC comes with ruby by default)
        ruby_bin=`which ruby`
        if [[ -z ${ruby_bin} ]]; then
            echo "Ruby is not installed."
            exit
        fi

        # Homebrew install
        # Refer: https://brew.sh/
        pkg_installer=`which brew`
        if [[ -z ${pkg_installer} ]] ; then
            ${ruby_bin} -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        else
            ${pkg_installer} update > /dev/null
            ${pkg_installer} upgrade > /dev/null
        fi
        echo "${pkg_installer}"
    elif [[ ${platform} == 'Ubuntu' ]]; then
        pkg_installer=`which apt-get`
        _pkgInstall "${platform}" "apt-transport-https" "${pkg_installer}"
        # adding google cloud key to apt
        curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | _runAsRoot apt-key add -
        _runAsRoot add-apt-repository -y ppa:rmescandon/yq > /dev/null 2>&1
        _runAsRoot touch /etc/apt/sources.list.d/kubernetes.list
        echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | _runAsRoot tee -a /etc/apt/sources.list.d/kubernetes.list
        _runAsRoot ${pkg_installer} update -y > /dev/null
        echo "${pkg_installer}"
    elif [[ ${platform} == 'Linux' ]]; then
        pkg_installer=`which yum`
        _runAsRoot dd of=/etc/yum.repos.d/kubernetes.repo  2> /dev/null <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
        _runAsRoot ${pkg_installer} update -y > /dev/null
        _pkgInstall "${platform}" "vim-enhanced" "${pkg_installer}"
        _pkgInstall "${platform}" "epel-release" "${pkg_installer}"
        echo "${pkg_installer}"
    fi
}

# Install DMG
_installDmg() {
    set -x
    tempd=$(mktemp -d)
    curl $1 2> /dev/null > $tempd/pkg.dmg
    listing=$(sudo hdiutil attach $tempd/pkg.dmg | grep Volumes)
    volume=$(echo "$listing" | cut -f 3)
    if [ -e "$volume"/*.app ]; then
      sudo cp -rf "$volume"/*.app /Applications
    elif [ -e "$volume"/*.pkg ]; then
      package=$(ls -1 | grep *.pkg | head -1)
      ((${ARG_DEBUG})) && echo "Installing DMG package ${package}..."
      sudo installer -pkg "$volume"/"$package".pkg -target /
    fi
    sudo hdiutil detach "$(echo "$listing" | cut -f 1)"
    rm -rf $tempd
    set +x
}

# Install Packages
_pkgInstall() {
    local platform=$1
    local package=$2
    local pkg_installer=$3
    if [[ ${platform} == 'MacOS' ]]; then
        ${pkg_installer} list ${package} > /dev/null 2>&1
        brew_present=$?
       ${pkg_installer} cask list ${package} > /dev/null 2>&1
        brew_cask_present=$?
        (( brew_present && brew_cask_present )) && { ((${ARG_DEBUG})) && echo "Installing ${package}..."; ${pkg_installer} install ${package} > /dev/null 2>&1; initial_status=$?; (( initial_status )) && ${pkg_installer} cask install ${package} > /dev/null 2>&1; }
    elif [[ ${platform} == 'Ubuntu' ]]; then
        dpkg -s "$package" >/dev/null 2>&1 || { ((${ARG_DEBUG})) && echo "Installing ${package}..."; _runAsRoot ${pkg_installer} install ${package} -y > /dev/null; }
    elif [[ ${platform} == 'Linux' ]]; then
        if ! rpm -qa | grep -qw ${package}; then
            ((${ARG_DEBUG})) && echo "Installing ${package}..."
            _runAsRoot ${pkg_installer} install ${package} -y > /dev/null
            if [[ $? -gt 0 ]]; then
                new_package=`yum search ${package} | grep -e "^${package}[0-9]\." | awk -F'.' '{ print $1 }' | sort -nr | head -1`
                ((${ARG_DEBUG})) && echo "Installing ${new_package}..."
                _runAsRoot ${pkg_installer} install ${new_package} -y > /dev/null
                pkg_bin=`which ${new_package}`
                if [[ -z "${pkg_bin}" ]]; then
                    ((${ARG_DEBUG})) && echo "Installing ${package}..."
                    _runAsRoot ln -s ${pkg_bin} /usr/bin/${package}
                fi
            fi
        fi
    else
        echo 'OS not supported !!!'
    fi
}

# Install pip packages
_pipInstall() {
    local platform=$1
    local package=$2
    pip_bin=`which pip3`
    if [[ `pip3 list 2> /dev/null | grep -e "^${package}" | wc -l` -eq 0 ]]; then
        if [[ ${platform} == 'MacOS' ]]; then
            ((${ARG_DEBUG})) && echo "Installing ${package}..."
            ${pip_bin} install ${package}
        else
            ((${ARG_DEBUG})) && echo "Installing ${package}..."
            _runAsRoot ${pip_bin} install ${package}
        fi
    fi
}

# Brew cask installs
_caskInstall() {
    local pkgs=$@
    local pkg_installer=`which brew`
    for package in ${pkgs}; do
        ((${ARG_DEBUG})) && echo "Installing ${package}..."
        if [[ `${pkg_installer} cask list | grep ${package} | wc -l` -eq 0 ]]; then
            ${pkg_installer} cask  install ${package} > /dev/null
        else
            echo "Package ${package} already installed."
        fi
    done
}

# Profile Setup
_profiles() {
    local platform=$1
    local force=$2
    local bash_profile_file=~/.bash_profile
    local bash_rc_file=~/.bashrc
    # Copy custom bash config and initiate
    ((${ARG_DEBUG})) && echo 'Copying the env profiles.'

    # Adding system bashrc
    if [[ $(cat ${bash_rc_file} 2> /dev/null | \grep -v '^#' | \grep '/etc/bashrc' | \grep 'bashrc' | wc -l) -eq 0 ]]; then
        ((${ARG_DEBUG})) && echo 'Setting up /etc/bashrc'
        [[ -f /etc/bashrc ]] && echo '[ -r /etc/bashrc ] && . /etc/bashrc' >> ${bash_rc_file}
    fi

    # A custom profile where you can add your own aliases or functions
    if [[ $(cat ${bash_rc_file} 2> /dev/null | grep '.bash_office_profile' | wc -l) -eq 0 ]]; then
        ((${ARG_DEBUG})) && echo 'Setting up ~/.bash_office_profile - You can add your custom stuff here.'
        echo '[ -f ~/.bash_office_profile ] && . ~/.bash_office_profile' >> ${bash_rc_file}
    fi

    # Adding custom profiles
    if [[ $platform == 'MacOS' ]]; then
        for bash_prof in .bash_{std,mac}_profile; do
            ((${ARG_DEBUG})) && echo "Copying profile ${bash_prof}"
            cp ${PROFILES_DIR}/${bash_prof} ~/${bash_prof}
            if [[ $(cat ${bash_rc_file} 2> /dev/null | grep "${bash_prof}" | wc -l) -eq 0 ]]; then
                ((${ARG_DEBUG})) && echo "Setting up ${bash_prof}"
                echo "[ -f ~/${bash_prof} ] && . ~/${bash_prof}" >> ${bash_rc_file}
            fi
        done
    else
        for bash_prof in .bash_{std,nix}_profile; do
            ((${ARG_DEBUG})) && echo "Copying profile ${bash_prof}"
            cp ${PROFILES_DIR}/${bash_prof} ~/${bash_prof}
            if [[ $(cat ${bash_rc_file} 2> /dev/null | grep "${bash_prof}" | wc -l) -eq 0 ]]; then
                ((${ARG_DEBUG})) && echo "Setting up ${bash_prof}"
                echo "[ -f ~/${bash_prof} ] && . ~/${bash_prof}" >> ${bash_rc_file}
            fi
        done
    fi

    # Calling .bashrc in .bash_profile
    file_length=$(cat ${bash_profile_file} | wc -l | tr -d '[:space:]')
    bash_rc_pos=$(cat -n ${bash_profile_file} | \grep '~/.bashrc' | sed -e 's/^[ \t]*//' | \grep -Ev '^\d+\t?#' | awk '{ print $1 }' | head -1)
    if [[ $(cat ${bash_profile_file} 2> /dev/null | \grep '~/.bashrc' | wc -l | tr -d '[:space:]') -eq 0 ]]; then
        ((${ARG_DEBUG})) && echo 'Setting up ~/.bashrc'
        echo '[ -f ~/.bashrc ] && . ~/.bashrc' >> ${bash_profile_file}
    elif [[ ${bash_rc_pos} -le $((file_length - 1)) ]]; then
        ((${ARG_DEBUG})) && echo "Rearranging position of ~/.bashrc profile in ${bash_profile_file}"
        echo '[ -f ~/.bashrc ] && . ~/.bashrc' >> ${bash_profile_file}
        if [[ $platform == 'MacOS' ]]; then
            sed -i '' "${bash_rc_pos}d" ${bash_profile_file}
        else
            sed -i "${bash_rc_pos}d" ${bash_profile_file}
        fi
    fi

    # Copying all app profiles.
    for conf in ${APP_PROFILES}; do
        if [[ "${conf}" == ".gitconfig" ]]; then
            # git config
            if [[ ! -f ~/.gitconfig ]]; then
                ((${ARG_DEBUG})) && echo "Copying the profile ${conf}.."
                cp ${PROFILES_DIR}/.gitconfig ~/.gitconfig
                echo 'What is your name ?'
                read name
                if [[ ! -z "${name}" ]]; then
                    git config --global user.name "${name}"
                fi
                echo 'What is your email ?'
                read email
                if [[ ! -z "${email}" ]]; then
                    git config --global user.email "${email}"
                fi
            elif [[ -f ~/.gitconfig ]] && [[ "${force}" == 'Y' ]]; then
                name=$(git config user.name)
                email=$(git config user.email)
                ((${ARG_DEBUG})) && echo "Copying the profile ${conf}.."
                cp ${PROFILES_DIR}/.gitconfig ~/.gitconfig
                git config --global user.name "${name}"
                git config --global user.email "${email}"
            fi
        elif [[ ! -f ~/${conf} ]] || [[ ${force} == 'Y' ]]; then
            ((${ARG_DEBUG})) && echo "Copying the profile ${conf}.."
            cp ${PROFILES_DIR}/${conf} ~/${conf}
        fi
    done

    [[ ! -d ~/.bin ]] && { mkdir ~/.bin; cp ${BIN_DIR}/* ~/.bin/; } || { cp ${BIN_DIR}/* ~/.bin/; }

    if [[ $platform == 'MacOS' ]]; then
        # Create ~/.themes directory
        if [[ ! -d ~/.themes/iterm2 ]]; then
            mkdir -p ~/.themes/iterm2
            ((${ARG_DEBUG})) && echo 'Copying themes to ~/.themes ..'
            cp ${THEMES_DIR}/* ~/.themes/
            mv ~/.themes/com.googlecode.iterm2.plist ~/.themes/iterm2/
        fi

        # Copy sublime custom profiles
        if [[ -d ~/Library/Application\ Support/Sublime\ Text\ 3 ]]; then
            if [[ ! -f ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Preferences.sublime-settings ]] || [[ ${force} == 'Y' ]]; then
            	for sprofile in Preferences.sublime-settings Solarized.dark.sublime-color-scheme Solarized.light.sublime-color-scheme; do
            		((${ARG_DEBUG})) && echo "Copying the profile ${sprofile}.."
                	cp ${THEMES_DIR}/${sprofile} ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/
                done
            fi
        fi

        # Copy Terminal and iTerm2 profile
        if [[ -d ~/Library/Preferences ]]; then
            if [[ ! -f ~/Library/Preferences/com.apple.Terminal.plist ]] || [[ ${force} == 'Y' ]]; then
                ((${ARG_DEBUG})) && echo 'Copying the terminal profile com.apple.Terminal.plist..'
                cp ~/.themes/com.apple.Terminal.plist ~/Library/Preferences/com.apple.Terminal.plist
            fi
            if [[ ! -f ~/Library/Preferences/com.googlecode.iterm2.plist ]] || [[ ${force} == 'Y' ]]; then
                # plutil -convert binary1 ~/.themes/iterm2/com.apple.Terminal.plist (to convert to plist binary)
                # plutil -convert xml1 ~/.themes/iterm2/com.apple.Terminal.plist (to convert to plist xml)
                ((${ARG_DEBUG})) && echo 'Copying the iTerm2 profile com.googlecode.iterm2.plist..'
                defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "~/.themes/iterm2"
                defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
            fi
        fi

        # Terminal Profile
        if [[ $(defaults read com.apple.Terminal "Default Window Settings") != 'Pro' ]]; then
            defaults write com.apple.Terminal "Default Window Settings" Pro
            defaults write com.apple.Terminal "Startup Window Settings" Pro
        fi
    fi
}

# Custom Package install
_pkgInstallProcess() {
    local pkgs=$@
    local platform=$(_getPlatform)
    for package in ${pkgs}; do
        echo "Installing package ${package}"
        if [[ ${package} =~ ^pip[0-9]?$ ]]; then
            python_bin=`which python`
            python3_bin=`which python3`
            if [[ ${platform} == 'MacOS' ]]; then
                python_bin=`which python3`
            fi
            if [[ -z `which ${package}` ]]; then
                ((${ARG_DEBUG})) && echo 'Installing pip...'
                curl -O https://bootstrap.pypa.io/get-pip.py 2> /dev/null
                if [[ ${platform} == 'MacOS' ]]; then
                    ${python3_bin} get-pip.py
                else
                    _runAsRoot ${python3_bin} get-pip.py
                fi
            fi
        elif [[ ${package} =~ helm$ ]] && [[ ${platform} != 'MacOS' ]]; then
            ((${ARG_DEBUG})) && echo 'Installing helm...'
            curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get -o get_helm.sh 2> /dev/null
            bash get_helm.sh
        elif [[ ${package} == "kubernetes-cli" ]] && [[ ${platform} != 'MacOS' ]]; then
            _pkgInstall "${platform}" "kubectl" "${pkg_installer}"
        elif [[ ${package} == 'kops' ]] && [[ ${platform} != 'MacOS' ]]; then
            ((${ARG_DEBUG})) && echo 'Installing kops...'
            wget -O kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
            chmod +x ./kops
            _runAsRoot mv ./kops /usr/local/bin/
        else
            _pkgInstall "${platform}" "${package}" "${pkg_installer}"
        fi
    done
}

# Main Function
function main() {
    _getOptions $@
    ARG_ENV=$(_capitalize ${ARG_ENV})
    platform=$(_getPlatform)
    pkg_installer=''

    pkg_installer=$(_baseSetup ${platform})
    ((${ARG_DEBUG})) && echo "Package installer is ${pkg_installer}"

    PKG_INSTALLS="${PKG_INSTALLS_COMMON}"

    if [[ ${ARG_ENV} == 'PERSONAL' ]]; then
        _ask "Do you want to install work related packages \"${PKG_INSTALLS_WORK}\""
        if [[ $? -eq 1 ]]; then
            PKG_INSTALLS="${PKG_INSTALLS} ${PKG_INSTALLS_WORK}"
        fi
        _pkgInstallProcess ${PKG_INSTALLS}
        _ask "Do you want to install these packages \"${PKG_INSTALLS_PERSONAL}\""
        if [[ $? -eq 1 ]] && [[ ${platform} == 'MacOS' ]]; then
            _caskInstall ${PKG_INSTALLS_PERSONAL}
        fi
    elif [[ ${ARG_ENV} == 'WORK' ]]; then
        _ask "Do you want to install work related packages \"${PKG_INSTALLS_WORK}\""
        if [[ $? -eq 1 ]]; then
            PKG_INSTALLS="${PKG_INSTALLS} ${PKG_INSTALLS_WORK}"
        fi
        _pkgInstallProcess ${PKG_INSTALLS}
    fi

    for pip_package in ${PIP_INSTALLS}; do
        echo "Installing package ${pip_package}"
        _pipInstall ${platform} ${pip_package} > /dev/null
    done

    if [[ ${platform} == 'MacOS' ]]; then
        pkg='Komodo-Edit'
        regex=`echo ${pkg} | sed 's/-/ /'`
        if [[ `pkgutil --pkgs | grep -i ${pkg} | wc -l` -eq 0 ]] && [[ `ls /Applications/ | grep -e "${regex}" | wc -l` -eq 0 ]]; then
            komodo_string=`curl http://downloads.activestate.com/Komodo/releases/11.1.0/ 2> /dev/null | grep 'Komodo-Edit-' | grep 'dmg' | sed 's/.*>\(Komodo-Edit-.*\.dmg\)<.*/\1/'`
            _installDmg "http://downloads.activestate.com/Komodo/releases/11.1.0/${komodo_string}"
        fi
    fi

    if [[ ${ARG_FORCE} -eq 1 ]]; then
        ((${ARG_DEBUG})) && echo 'Overwriting if any profiles exists with --force option !!!'
        _profiles ${platform} 'Y'
    else
        _profiles ${platform} 'N'
    fi
}

main $@

# Reference:
# Bash colour coding:  https://misc.flogisoft.com/bash/tip_colors_and_formatting
# jq:  https://github.com/stedolan/jq.git
# jq: https://jqplay.org/
# yq: https://yq.readthedocs.io/en/latest/
# yq: https://github.com/mikefarah/yq
# kubectl: curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin
# kops: wget -O kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64 && chmod +x ./kops && sudo mv ./kops /usr/local/bin/
# zsh: https://ohmyz.sh/
# jid: https://github.com/simeji/jid

