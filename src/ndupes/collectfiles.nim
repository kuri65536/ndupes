##[ collectfiles.nim
=========================

License: MIT, see LICENSE
]##
import std/dirs
import std/os
import std/paths

import common
import dbif_sqlite as dbif
import extract
import progress


type
  path_info = tuple[f: Path]

  optscol = tuple[f_quiet: bool]


iterator walk(paths: openarray[Path]): path_info =
    for path in paths:
        if os.fileExists(path.string):
            yield (path, )
            continue
        for i in dirs.walkDirRec(path):
            yield (i, )


proc run*(db: dbif.DBInfo, paths: seq[Path], opts: optscol): int =
    var stat = progress.prog_stat2(f_quiet: opts.f_quiet)
    for pi in walk(paths):
        stat = progress.show_collect(pi.f, stat)
        var fi1 = extract.extract1(pi.f, true)
        if isNil(fi1):
            continue
        let fi0 = dbif.load(db, fi1.path)
        if isNil(fi0):
            stdout.write("listup: scanned and saved... " & pi.f.string & "\n")
            dbif.save(db, fi1)
            continue
        if common.equals(fi0, fi1):
            stdout.write("listup: already scanned  ... " & pi.f.string & "\n")
            continue
        block:
            stdout.write("listup: detected as new one. " & pi.f.string & "\n")
            dbif.update(db, fi0.uid, fi1)
    progress.end_collect(stat.f_quiet)

