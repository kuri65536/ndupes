# Package

version       = "0.1.0"
author        = "shimoda"
description   = "A lightweight duplicate file manager optimized for memory-constrained systems"
license       = "MIT"
srcDir        = "src"
bin           = @["ndupes"]


# Dependencies

requires "nim >= 2.0.4"

before build:
    exec "nim c -o:bin/version -r src/ndupes/version.nim"

