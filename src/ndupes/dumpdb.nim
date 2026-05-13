##[ dumpdb.nim
====================

License: MIT, see LICENSE
]##
import std/paths
import std/strutils

import common
import dbif_sqlite as db


proc dumprec(src: common.file_info, opts: set[common.dump_options]): void =
    proc short_hash(s: array[32, uint8]): string =
        return toHex(s[0], 2) & toHex(s[1], 2) & toHex(s[2], 2) &
               toHex(s[3], 2) & toHex(s[4], 2) & toHex(s[5], 2)
    proc path_fmt(s: Path): string =
        const width = 20
        let p = s.string
        result = if p.len > width: p[^width ..^ 1] else: p
        result = align(result, width)

    var line = ""
    line &= ", " & align($src.size, 10)
    line &= ", " & align($src.count, 6)
    line &= ", " & align($src.inode, 6)
    line &= ", " & align($src.devid, 10)
    line &= ", " & short_hash(src.hash)
    line &= ", " & align($src.error, 2)
    line &= ", " & align($src.done, 2)
    line &= ", " & path_fmt(src.path)
    stdout.write(line[2 ..^ 1] & "\n")


proc fetch(src: db.DBInfo, prev: common.file_info,
           opts: set[common.dump_options]): common.file_info =
    if opts.contains(dup_level2):
        discard
    if opts.contains(dup_level1):
        discard
    var key: common.uid_type
    if not isNil(prev):
        key = prev.uid
    return db.get_all(src, key)


proc run*(src: db.DBInfo, opts: set[common.dump_options]): int =
    ##[
    ]##
    var fi = fetch(src, nil, opts)
    while not isNil(fi):
        dumprec(fi, opts)
        fi = fetch(src, fi, opts)

