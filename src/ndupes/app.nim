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
import progress
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

    stdout.write("### phase 1: collect files...\n")
    var stat = progress.prog_stat2(f_quiet: not opts.f_progress)
    for pi in walk(opts.paths):
        stat = progress.show_collect(pi.f, stat)
        var fi1 = extract.extract1(pi.f, true)
        if isNil(fi1):
            continue
        let fi0 = db.load(tmp, fi1.path)
        if isNil(fi0):
            stdout.write("listup: scanned and saved... " & pi.f.string & "\n")
            db.save(tmp, fi1)
            continue
        if common.equals(fi0, fi1):
            stdout.write("listup: already scanned  ... " & pi.f.string & "\n")
            continue
        block:
            stdout.write("listup: detected as new one. " & pi.f.string & "\n")
            db.update(tmp, fi0.uid, fi1)
    progress.end_collect(stat.f_quiet)

    stdout.write("### phase 2: calculate hash...\n")
    let ret2 = calchash.run(tmp, (calc_method(opts.n_method), opts.size,
                                  not opts.f_progress))
    if ret2 != 0 or opts.runflags.contains(until_hash):
        return ret2

    stdout.write("### phase 3: remove duplicates...\n")
    return removedups.run(tmp, (opts.runflags.contains(apply), ))


when isMainModule:
    discard

