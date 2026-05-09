##[ calchash.nim
=========================

License: MIT, see LICENSE
]##
import std/logging
import std/paths

import common
import dbif_sqlite as db


type
  optscalc* = tuple[n: common.calc_method, size: int]


proc calc(src: Path, n: common.calc_method): array[32, uint8] =
    discard


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
        let hash = block:
                calc(fi.path, opts.n)
        block:
            info("hash:update to => " & $hash)
            var tmp = fi
            tmp.hash = hash
            db.update(src, fi.uid, tmp)
    return 0

