##[ calchash.nim
=========================

License: MIT, see LICENSE
]##
import std/logging
import std/paths

import common
import dbif_sqlite as db
import progress

when defined(use_sha2):
  import checksums/md5
  import calchash_sha256 as calcsha2
else:
  import std/md5


type
  optscalc* = tuple[n: common.calc_method, size: int]


proc filemd5*(src: Path, size: int, blk = 8192): array[32, uint8] =
    debug("hash: enter, " & $size & ":" & src.string)
    var ctx: MD5Context
    md5.md5Init(ctx)

    var fp: File
    if not system.open(fp, src.string):
        raise newException(IOError, "")
    defer: fp.close()

    var cur = 0
    var stat: progress.prog_stat
    while true:
        var buf = newSeq[uint8](blk)
        let n = readBuffer(fp, addr(buf[0]), blk)
        if n < 1:
            break
        cur += n
        stat = progress.show_hash(src, cur, size, stat)
        buf.setLen(n)
        md5.md5Update(ctx, buf)
        if n < blk:
            break

    var tmp: array[0..15, uint8]
    md5.md5Final(ctx, tmp)
    for i in 0 .. 15:
        result[i] = tmp[i]
    debug("hash: end, " & $result[0] & $result[1] & $result[2])


proc calc(src: Path, size: int, n: common.calc_method): array[32, uint8] =
    stdout.write("hash  : " & src.string & "\n")
    when defined(use_sha2):
        if n == method_sha256:
            return filesha256(src)
    else:
        if n == method_sha256:
            warn("specified: sha256 not enabled in build, fallback to md5")
    return filemd5(src, size)


proc run*(src: db.DBInfo, opts: optscalc): int =
    ##[ calculate hashes with files in DB.

        for reducing memory usage,

        - get just one file from DB per loop
        - calculate hash with blocksize reading
    ]##
    while true:
        let fi = db.get_unhash(src, opts.size)
        if isNil(fi):
            break
        let hash = try:
                calc(fi.path, fi.size, opts.n)
            except:
                var tmp = fi
                common.mark_error(tmp)
                db.update(src, fi.uid, tmp)
                continue
        block:
            info("hash:update to => " & $hash)
            var tmp = fi
            tmp.hash = hash
            db.update(src, fi.uid, tmp)

        discard db.update_hash_sameinode(src, fi.inode, fi.hash)
    return 0

