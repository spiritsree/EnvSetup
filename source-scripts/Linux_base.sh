_env_base_setup_os() {
    local pkg_installer=$(command -v yum)
    sudo dd of=/etc/yum.repos.d/kubernetes.repo  2> /dev/null <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
    sudo "${pkg_installer}" update -y > /dev/null 2>&1
    sudo "${pkg_installer}" install vim-enhanced -y > /dev/null 2>&1
    sudo "${pkg_installer}" install epel-release -y > /dev/null 2>&1

    # Python installation
    # sudo "${pkg_installer}" install @development zlib-devel bzip2 bzip2-devel readline-devel sqlite \
    #                                sqlite-devel openssl-devel xz xz-devel libffi-devel findutils > /dev/null 2>&1
    # curl https://pyenv.run 2> /dev/null | bash 2> /dev/null
    # export PYENV_ROOT="$HOME/.pyenv"
    # export PATH="$PYENV_ROOT/bin:$PATH"
    # if command -v pyenv 1>/dev/null 2>&1; then
    #    eval "$(pyenv init -)"
    #    eval "$(pyenv virtualenv-init -)"
    # fi
    # local python_version=$(pyenv install --list | awk '{ print $1 }' | grep -E '^3.7' | tail -1)
    # if [[ -n "${python_version}" ]]; then
    #    pyenv install "${python_version}" > /dev/null 2>&1
    #    pyenv global "${python_version}"
    # fi
    sudo "${pkg_installer}" install python3 -y > /dev/null 2>&1
    curl -O https://bootstrap.pypa.io/get-pip.py 2> /dev/null
    sudo python3 get-pip.py > /dev/null 2>&1
    pip3 install --upgrade pip > /dev/null 2>&1
}
