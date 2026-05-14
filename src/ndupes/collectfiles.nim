##[ collectfiles.nim
=========================

License: MIT, see LICENSE
]##
import std/dirs
import std/logging
import std/os
import std/paths

import common
import dbif_sqlite as dbif
import extract
import progress


type
  path_info = tuple[f: Path]

  optscol = tuple[minsize: int,
                  f_quiet: bool]


iterator walk(paths: openarray[Path]): path_info =
    for path in paths:
        if os.fileExists(path.string):
            yield (path, )
            continue

        if not os.dirExists(path.string):
            continue

        let root_device = os.getFileInfo(path.string, false).id.device
        var stack = @[path]
        while len(stack) > 0:
            let cur = stack.pop()
            try:
                for (k, i) in dirs.walkDir(cur):
                    if k == pcFile:
                        yield (i, )
                        continue
                    if k == pcDir:
                        let devid = os.getFileInfo(i.string, false).id.device
                        if devid == root_device:
                            stack.add(i)
                            continue
                        info("listup: ignored defference device " & i.string)
                        continue
                    debug("listup: ignored " & i.string & "(" & $k & ")")
            except OSError:
                error("listup: skip " & getCurrentExceptionMsg())


proc run*(db: dbif.DBInfo, paths: seq[Path], opts: optscol): int =
    var stat = progress.initProgStat2(opts.f_quiet)
    for pi in walk(paths):
        stat = progress.show_collect(pi.f, stat)
        var fi1 = extract.extract1(pi.f, true, opts.minsize)
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
    progress.end_collect(stat, "collecting phase ")

