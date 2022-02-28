# oracle-linux-sync

## Table of contents
* [Description](#description)
* [Dependencies](#dependencies)
* [Setup](#setup)
* [Usage](#usage)

## Description
This bash script syncs the *.rpm packages of one or more OracleLinux repositories based on the index URI. Optionally it provides the possibility to create the YUM meta information based on the createrepo_c program. It can be run in a non-root user context.

The Project is written in GNU bash, Version 5.

## Dependencies
* mandatory : GNU bash          >= 5
* optional : createrepo_c      >= 0.18.0 (https://github.com/rpm-software-management/createrepo_c)

## Setup
To run this project, you need to clone it to your local computer and run it as a shell script.

```
$ cd /tmp
$ git clone https://github.com/initd3v/oracle-linux-sync.git
$ nano -w /tmp/oracle-linux-sync/oracle-linux-sync.sh
```
## Usage

### Running the script

To run this project, you must add the execution flag for the user context to the bash file. Afterwards execute it in a bash shell. 

```
$ chmod u+x /tmp/oracle-linux-sync/oracle-linux-sync.sh
$ /tmp/oracle-linux-sync/oracle-linux-sync.sh
```

### Supported Options

The folowing configuration options are valid:

| Option syntax        | Description                                                         | Necessity | Supported value(s)  | Default |
|:---------------------|:--------------------------------------------------------------------|:---------:|:-------------------:|:-------:|
| -h \| --help         | display help page                                                   | optional  | -                   | -       |
| -v \| --verbosity    | adjust level of verbosity (0 = no logging \| 1 = systemctl and log file logging \| 2 = systemctl, log file logging and terminal output | optional  | INT from 0 and 2 | 2      |
| -c \| --configuration| set path to configuration file (parameters will be overwritten)     | optional  | STRING              | -       |
| -d \| --directory    | set path to repository folder where RPM packages and meta information should be saved | mandatory | STRING | -  |
| -u \| --url          | pass URL to Oracle Linux index page (for multiple URL, pass the argument multiple times; the character = will be escaped to %3D) | mandatory | STRING | - |
| -m \| --metadata     | set path to createrepo_c binary - if passed, the meta information will be geenrated | optional | STRING | -     |

