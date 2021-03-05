# Terraform Version Management

## tfenv

`tfenv` is a tool to install and manage different versions of terraform

* List remote available versions

```
$ tfenv list-remote
0.14.7
0.14.6
0.14.5

```

* List of installed versions

```
$ tfenv list
No versions available. Please install one with: tfenv install
```

* Install a terraform vertsion

```
$ tfenv install 0.13.6
$ tfenv list
  0.13.6
No default set. Set with 'tfenv use <version>'

$ tfenv use 0.13.6
Switching default version to v0.13.6
Switching completed

$ tfenv list
* 0.13.6 (set by /usr/local/Cellar/tfenv/2.2.0/version)
```

* Select a terraform version to use locally

```
$ tfenv use 0.13.6
Switching default version to v0.13.6
Switching completed

$ tfenv list
  0.14.7
* 0.13.6 (set by /usr/local/Cellar/tfenv/2.2.0/version)
```
