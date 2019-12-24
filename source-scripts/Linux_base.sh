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
    "${pkg_installer}" vim-enhanced -y > /dev/null 2>&1
    "${pkg_installer}" epel-release -y > /dev/null 2>&1
}
