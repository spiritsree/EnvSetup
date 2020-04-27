# shellcheck shell=bash

_env_base_setup_os() {
    # Ruby (MAC comes with ruby by default)
    local ruby_bin pkg_installer python_version
    ruby_bin=$(command -v ruby)
    if [[ -z "${ruby_bin}" ]]; then
        echo "Ruby is not installed."
        exit
    fi

    # Homebrew install
    pkg_installer=$(command -v brew)
    if [[ -z "${pkg_installer}" ]] ; then
        "${ruby_bin}" -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    else
        "${pkg_installer}" update > /dev/null
        "${pkg_installer}" upgrade > /dev/null
    fi

    # Disable brew analytics
    "${pkg_installer}" analytics off

    # Installing brew services to
    # Manage background services with macOS' launchctl daemon manager
    "${pkg_installer}" services list > /dev/null 2>&1

    # Python install
    "${pkg_installer}" install readline xz > /dev/null 2>&1
    "${pkg_installer}" install pyenv pyenv-virtualenv > /dev/null 2>&1
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    if command -v pyenv 1>/dev/null 2>&1; then
        eval "$(pyenv init -)"
        eval "$(pyenv virtualenv-init -)"
    fi
    python_version=$(pyenv install --list | awk '{ print $1 }' | grep -E '^3.7' | tail -1)
    if [[ -n "${python_version}" ]]; then
        pyenv install "${python_version}" > /dev/null 2>&1
        pyenv global "${python_version}"
    fi
}

_secure_dns_setup() {
    local pkg_installer_bin stubby_config
    pkg_installer_bin=$(command -v brew)
    stubby_config="/usr/local/etc/stubby/stubby.yml"
    # Stubby Config
    if ! diff <(shasum "${stubby_config}" | awk '{ print $1 }') \
              <(shasum themes/stubby.yml | awk '{ print $1 }') > /dev/null 2>&1; then
        ((ARG_DEBUG)) && echo 'Copying stubby config...'
        cp themes/stubby.yml "${stubby_config}"
    fi

    # Start stubby service
    if [[ $(pgrep "[s]tubby" | wc -l) -eq 0 ]]; then
        ((ARG_DEBUG)) && echo 'Starting stubby service...'
        sudo "${pkg_installer_bin}" services start stubby > /dev/null 2>&1
    fi

    # Verify if DNS resoultion works
    if dig +short +time=5 @127.0.0.1 www.example.com > /dev/null 2>&1; then
        ((ARG_DEBUG)) && echo 'Stubby resolution success, hence setting system to use stubby...'
        sudo /usr/local/opt/stubby/sbin/stubby-setdns-macos.sh > /dev/null 2>&1
    fi
}
