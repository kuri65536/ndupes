# Package

version       = "0.2.0"
author        = "shimoda"
description   = "A lightweight duplicate file manager optimized for memory-constrained systems"
license       = "MIT"
srcDir        = "src"
bin           = @["ndupes"]


# Dependencies

requires "nim >= 2.0.4"

when true:
    switch("define", "use_sha2")
    requires "checksums >= 0.2.2"

before build:
    exec "nim c -o:bin/version -r src/ndupes/version.nim"


## debian package
let pfx = "ndupes-" & version.split(".")[0 .. 1].join(".")
let tar = pfx & ".tar.gz"
let files = "LICENSE csource/*.c csource/compile_ndupes.sh"
task deb, "build debian package":
    exec "rm -rf build/" & pfx & " build/" & tar
    exec "mkdir -p build/" & pfx & "/debian"
    exec "cp -r build/debian-rules/* build/" & pfx & "/debian"
    exec "tar czvf build/" & tar & " " &
            "--transform s,^csource," & pfx & "/src, " &
            "--transform s,.*debian.mk,Makefile, " & files
    exec "cp -r " & files & " build/" & pfx
    exec "cd       build/" & pfx & "; debmake"
    exec "cd       build/" & pfx & "; EDITOR=/bin/true dpkg-source --commit . 1"
    exec "cd       build/" & pfx & "; debuild"

before deb:  # create csource
    exec "nim c --os:linux --compileOnly --genScript --nimcache:csource " &
         "src/ndupes.nim"

