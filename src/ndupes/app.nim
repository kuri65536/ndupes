##[ app.nim
=========================

License: MIT, see LICENSE
]##
import std/paths

import options
import dbif_sqlite as db


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

    # phase 1: collect data
    for pi in walk(opts.paths):
        let fi = extract.extract1(pi.f)


when isMainModule:
    discard

