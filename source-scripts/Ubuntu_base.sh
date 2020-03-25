_env_base_setup_os() {
    local lsb_release=$(command -p lsb_release -r -s)
    local pkg_installer=$(command -v apt-get)
    "${pkg_installer}" install apt-transport-https curl wget -y > /dev/null 2>&1;

    # adding google cloud key to apt
    google_key=$(mktemp /tmp/google_key.XXXXXXXXXX)
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg -o "${google_key}" > /dev/null 2>&1

    # shellcheck disable=SC2034
    sudo apt-key add "${google_key}" 2> /dev/null
    unlink "${google_key}"
    sudo add-apt-repository -y ppa:rmescandon/yq > /dev/null 2>&1
    sudo touch /etc/apt/sources.list.d/kubernetes.list

    # shellcheck disable=SC2034
    sudo echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' | tee /etc/apt/sources.list.d/kubernetes.list
    if [[ -n "${lsb_release}" ]]; then
        zsh_key=$(mktemp /tmp/zsh_key.XXXXXXXXXX)
        wget -q "https://download.opensuse.org/repositories/shells:zsh-users:zsh-completions/xUbuntu_${lsb_release}/Release.key" -O "${zsh_key}" 2> /dev/null
        # shellcheck disable=SC2034
        sudo apt-key add "${zsh_key}" 2> /dev/null
        unlink "${zsh_key}"
        # shellcheck disable=SC2034
        sudo echo "deb http://download.opensuse.org/repositories/shells:/zsh-users:/zsh-completions/xUbuntu_${lsb_release}/ /" | tee /etc/apt/sources.list.d/zsh-completions.list
    fi
    sudo "${pkg_installer}" update -y > /dev/null 2>&1
    # python3-distutils required by get-pip.py
    sudo "${pkg_installer}" install python3-distutils -y > /dev/null 2>&1

    # Python installation

    # sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
    #                        libreadline-dev libsqlite3-dev wget curl llvm \
    #                        libncurses5-dev libncursesw5-dev \
    #                        xz-utils tk-dev libffi-dev liblzma-dev python-openssl git > /dev/null 2>&1
    # curl https://pyenv.run 2> /dev/null | bash 2> /dev/null
    # export PYENV_ROOT="$HOME/.pyenv"
    # export PATH="$PYENV_ROOT/bin:$PATH"
    # if command -v pyenv 1>/dev/null 2>&1; then
    #     eval "$(pyenv init -)"
    #     eval "$(pyenv virtualenv-init -)"
    # fi
    # local python_version=$(pyenv install --list | awk '{ print $1 }' | grep -E '^3.7' | tail -1)
    # if [[ -n "${python_version}" ]]; then
    #     pyenv install "${python_version}" > /dev/null 2>&1
    #     pyenv global "${python_version}"
    # fi
    sudo apt-get install -y python3 python3-pip  > /dev/null 2>&1
    pip3 install --upgrade pip > /dev/null 2>&1
}


_secure_dns_setup() {
    local stubby_config="/etc/stubby/stubby.yml"

    # Stubby Config
    if ! diff <(shasum "${stubby_config}" | awk '{ print $1 }') \
              <(shasum themes/stubby.yml | awk '{ print $1 }') > /dev/null 2>&1; then
        ((ARG_DEBUG)) && echo 'Copying stubby config...'
        cp themes/stubby.yml "${stubby_config}"
    fi

    # Start stubby service
    if [[ $(systemctl status stubby | grep 'running' | wc -l) -eq 0 ]]; then
        ((ARG_DEBUG)) && echo 'Starting stubby service...'
        sudo systemctl start stubby > /dev/null 2>&1
    else
        ((ARG_DEBUG)) && echo 'Restarting stubby service...'
        sudo systemctl restart stubby > /dev/null 2>&1
    fi

    # Verify Stubby
    if [[ $(sudo netstat -lnptu | grep stubby | command grep "127.0.0.1:53" | wc -l) -gt 0 ]]; then
        ((ARG_DEBUG)) && echo 'Stubby listens on 127.0.0.1:53...'
    fi

    if [[ $(sudo netstat -lnptu | grep systemd-resolve | command grep "127.0.0.53:53" | wc -l) -gt 0 ]]; then
        ((ARG_DEBUG)) && echo 'systemd-resolve listens on 127.0.0.53:53...'
    fi

    # Verify if DNS resoultion works
    if $(dig +short +time=5 @127.0.0.1 www.example.com > /dev/null 2>&1); then
        ((ARG_DEBUG)) && echo 'Stubby resolution success, hence setting system to use stubby...'
        local netplan_file=$(find /etc/netplan -type f | command grep yaml | head -1)
        local net_interfaces=$(yq read -j "${netplan_file}" network.ethernets | jq 'keys[]')
        for net_iface in $net_interfaces; do
            sudo yq write -i "${netplan_file}" network.ethernets.$net_iface.nameservers.addresses[+] "127.0.0.1"
        done
        sudo netplan apply > /dev/null 2>&1 && sleep 5
        if [[ $(systemd-resolve --status | command grep "127.0.0.1" | wc -l) -gt 0 ]]; then
            ((ARG_DEBUG)) && echo 'System is using stubby for resolution...'
        fi
    fi
}
