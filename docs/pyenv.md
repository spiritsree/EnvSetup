# Python Version Management

## Pyenv

pyenv is a tool for installing and managing multiple Python versions on macOS.

* List of installed versions

```
$ pyenv versions
* system
```

* Install a new python version

```
$ pyenv install -l (will list all the available versions)
$ pyenv install 3.8.0
$ pyenv versions
* system
  3.8.0
```

* Select the python version to use globally

```
$ pyenv global 3.8.0
$ pyenv versions
  system
* 3.8.0 (set by /Users/<user>/.pyenv/version)
```

* Select the python version to use locally for a project

```
$ pyenv local 3.7.5
$ pyenv versions
  system
* 3.7.5 (set by /Users/<user>/<proj>/.python-version)
```

* Uninstall a version

```
$ pyenv uninstall 3.7.3
```

* To fix the shim path issues

```
$ pyenv rehash
```

## Pyenv-virtualenv

pyenv-virtualenv enhances pyenv with a subcommand for managing virtual environments

* Create virtual environment

```
$ pyenv virtualenv 3.8.0 my-env
```

* Activate virtual environment

```
$ pyenv activate my-env
```

* Exit virtual environment

```
(my-env)$ pyenv deactivate
```

## Package management

with pyenv packages are isolated per env

```
$ pyenv virtualenv 3.7.3 my-proj
$ pyenv activate my-proj
(my-proj)$ pip list
Package    Version
---------- ---------
pip        19.1.1
setuptools 40.8.0
```
