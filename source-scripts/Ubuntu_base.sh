_env_base_setup_os() {
    local lsb_release=$(command -p lsb_release -r -s)
    local pkg_installer=$(command -v apt-get)
    "${pkg_installer}" install apt-transport-https -y > /dev/null 2>&1;

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
}
