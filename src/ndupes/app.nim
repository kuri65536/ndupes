##[ app.nim
=========================

License: MIT, see LICENSE
]##
import std/paths

import dbif_sqlite as db
import options


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
        var fi1 = extract.extract1(pi.f, true)
        if isNil(fi1):
            continue
        block:
            echo("scanned and saved... " & pi.f.string)
            db.save(tmp, fi1)


when isMainModule:
    discard

