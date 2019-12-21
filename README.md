## Introduction

chekcharden is to identify hardened security optoins for Linux-based devices during their runtime, putting chekcharden to the running system firstly before use it, then run preinstall.sh and procharden.sh in sequence.

## Dependencies

- [checksec](!http://www.trapkit.de/tools/checksec.html)

## Features

- check every user-level process on the embedded system.
- perform GCC Hardened options check, including stack protector, ASLR, NX, RELRO, FORTIFY and so on.

## Usage

1. Check if the gnu bash interpreter is available on host, then copy the cross-compiled bash binary into host if not existed.
```sh
./preinstall.sh
```

2. Perform GCC hardened options check for all the processes on host, including process executable itself and all its loaded libraries.
```sh
./procharden.sh
```
