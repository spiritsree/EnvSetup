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

}
