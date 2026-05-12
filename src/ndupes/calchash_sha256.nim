##[ calchash_sha256.nim
=========================

License: MIT, see LICENSE
]##
import std/logging
import std/paths

import checksums/sha2

import progress


proc calc*(src: Path, size: int, f_quiet: bool,
           blk = 8192): array[32, uint8] =
    ##[
    ]##
    var ctx = sha2.initSha_256()

    var fp: File
    if not system.open(fp, src.string):
        raise newException(IOError, "")
    defer: fp.close()

    var cur = 0
    var stat = progress.prog_stat(f_quiet: fquiet)
    while true:
        var buf = newSeq[char](blk)
        let n = readBuffer(fp, addr(buf[0]), blk)
        if n < 1:
            break
        cur += n
        stat = progress.show_hash(src, cur, size, stat)
        buf.setLen(n)
        sha2.update(ctx, buf)
        if n < blk:
            break

    var tmp = sha2.digest(ctx)
    for i in 0 .. 31:
        result[i] = uint8(tmp[i])
    debug("hash: end, " & $result[0] & $result[1] & $result[2])

