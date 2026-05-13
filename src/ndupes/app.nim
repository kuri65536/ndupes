##[ app.nim
=========================

License: MIT, see LICENSE
]##
import std/logging

import common
import calchash
import collectfiles
import dumpdb
import dbif_sqlite as db
import options
import removedups


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
    if   opts.runflags.contains(from_hash) or
         opts.runflags.contains(from_link):
        stdout.write("skipped..." & $opts.runflags)
    else:
        let ret1 = collectfiles.run(tmp, opts.paths,
                                    (opts.minsize, not opts.f_progress, ))
        if ret1 != 0:
            return ret1
    if opts.runflags.contains(until_collect):
        stdout.write("exit." & $opts.runflags); return 0

    stdout.write("### phase 2: calculate hash...\n")
    if opts.runflags.contains(from_link):
        stdout.write("skipped..." & $opts.runflags)
    else:
        let ret2 = calchash.run(tmp, (calc_method(opts.n_method), opts.size,
                                      not opts.f_progress))
        if ret2 != 0:
            return ret2
    if opts.runflags.contains(until_hash):
        stdout.write("exit." & $opts.runflags); return 0

    stdout.write("### phase 3: remove duplicates...\n")
    return removedups.run(tmp, (opts.runflags.contains(apply),
                                not opts.f_progress))


when isMainModule:
    discard

