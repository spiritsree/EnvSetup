_env_base_setup_os() {
    local lsb_release=$(command -p lsb_release -r -s)
    local pkg_installer=$(command -v apt-get)
    "${pkg_installer}" install apt-transport-https -y > /dev/null 2>&1;

    # adding google cloud key to apt
    google_key=$(mktemp /tmp/google_key.XXXXXXXXXX)
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg -o "${google_key}" > /dev/null 2>&1

    # shellcheck disable=SC2034
    apt_status=$(sudo apt-key add "${google_key}" 2> /dev/null)
    unlink "${google_key}"
    sudo add-apt-repository -y ppa:rmescandon/yq > /dev/null 2>&1
    sudo touch /etc/apt/sources.list.d/kubernetes.list

    # shellcheck disable=SC2034
    tee_out=$(sudo echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' | tee /etc/apt/sources.list.d/kubernetes.list)
    if [[ -n "${lsb_release}" ]]; then
        zsh_key=$(mktemp /tmp/zsh_key.XXXXXXXXXX)
        wget -q "https://download.opensuse.org/repositories/shells:zsh-users:zsh-completions/xUbuntu_${lsb_release}/Release.key" -O "${zsh_key}" 2> /dev/null
        # shellcheck disable=SC2034
        apt_status=$(sudo apt-key add "${zsh_key}" 2> /dev/null)
        unlink "${zsh_key}"
        # shellcheck disable=SC2034
        tee_out=$(sudo echo "deb http://download.opensuse.org/repositories/shells:/zsh-users:/zsh-completions/xUbuntu_${lsb_release}/ /" | tee /etc/apt/sources.list.d/zsh-completions.list)
    fi
    sudo "${pkg_installer}" update -y > /dev/null 2>&1
    # python3-distutils required by get-pip.py
    sudo "${pkg_installer}" install python3-distutils -y > /dev/null 2>&1
}
