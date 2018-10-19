## PROCHARDEN

procharden is to identify hardened security for Linux-based devices during its runtime, you need to port it to embedded device  firstly before you use it, it only target on unix-like system, then run preinstall.sh and procharden.sh when all that finished.

## Dependencies

- [checksec](!http://www.trapkit.de/tools/checksec.html)

## Features

- check every user-level process on the embedded device.
- perform GCC Hardened options check, including stack protector, ASLR, NX, RELRO, FORTIFY and so on.
- cross compiled Linux common command, file/readelf/bash.

## Usage

1. Check whether the gnu bash interpreter is available on host, then copy cross compiled bash binary into host if not existed.
```sh
./preinstall.sh
```

2. Perform GCC hardened options check for all the core process on host, including process executable itself and loaded libraries.
```sh
./procharden.sh
```
