# oracle-linux-sync

## Table of contents
* [About](#about)
* [Dependencies](#dependencies)
* [Setup](#setup)
* [Usage](#usage)

## About
This bash script syncs the *.rpm packages of one or more OracleLinux repositories based on the index URI. Optionally it provides the possibility to create the YUM metainformation based on the createrepo_c program. It can be run in a non-root user context.

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

The folowing configuration options are valid.

## Usage
To run this project, you must add the execution flag for the user context to the bash file. Afterwards execute it in a bash shell. 

```
$ chmod u+x /tmp/oracle-linux-sync/oracle-linux-sync.sh
$ /tmp/oracle-linux-sync/oracle-linux-sync.sh
```
