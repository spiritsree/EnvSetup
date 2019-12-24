_env_base_setup_os() {
    # Ruby (MAC comes with ruby by default)
    local ruby_bin=$(command -v ruby)
    if [[ -z "${ruby_bin}" ]]; then
        echo "Ruby is not installed."
        exit
    fi

    # Homebrew install
    local pkg_installer=$(command -v brew)
    if [[ -z "${pkg_installer}" ]] ; then
        "${ruby_bin}" -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    else
        "${pkg_installer}" update > /dev/null
        "${pkg_installer}" upgrade > /dev/null
    fi

    # Python install
    "${pkg_installer}" install readline xz > /dev/null 2>&1
    "${pkg_installer}" install pyenv > /dev/null 2>&1
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    if command -v pyenv 1>/dev/null 2>&1; then
        eval "$(pyenv init -)"
        eval "$(pyenv virtualenv-init -)"
    fi
    local python_version=$(pyenv install --list | awk '{ print $1 }' | grep -E '^3.7' | tail -1)
    if [[ -n "${python_version}" ]]; then
        pyenv install "${python_version}" > /dev/null 2>&1
        pyenv global "${python_version}"
    fi
}
