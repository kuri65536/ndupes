##[ app.nim
=========================

License: MIT, see LICENSE
]##
import std/dirs
import std/logging
import std/os
import std/paths

import common
import calchash
import dumpdb
import extract
import dbif_sqlite as db
import options
import removedups


type
  path_info = tuple[f: Path]


iterator walk(paths: openarray[Path]): path_info =
    for path in paths:
        if os.fileExists(path.string):
            yield (path, )
            continue
        for i in dirs.walkDirRec(path):
            yield (i, )


proc run*(args: openarray[string]): int =
    ##[
    ]##
    let opts = options.parseargs(args)

    let tmp = db.open(opts.tmpdb)
    defer: db.close(tmp)

    if opts.runflags.contains(dump):
        info("mode: dump record...")
        return dumpdb.run(tmp, opts.dumpflags)
    info("mode: normal...")

    # phase 1: collect data
    for pi in walk(opts.paths):
        var fi1 = extract.extract1(pi.f, true)
        if isNil(fi1):
            continue
        let fi0 = db.load(tmp, fi1.path)
        if isNil(fi0):
            echo("scanned and saved... " & pi.f.string)
            db.save(tmp, fi1)
            continue
        if common.equals(fi0, fi1):
            echo("already scanned  ... " & pi.f.string)
            continue
        block:
            echo("detected as new one. " & pi.f.string)
            db.update(tmp, fi0.uid, fi1)

    # phase 2: calculate hash
    let ret2 = calchash.run(tmp, (calc_method(opts.n_method), opts.size))
    if ret2 != 0 or opts.runflags.contains(until_filter):
        return ret2

    # phase 3: remove dups
    return removedups.run(tmp, (opts.runflags.contains(apply), ))


when isMainModule:
    discard

