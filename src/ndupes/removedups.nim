##[ removedups.nim
=========================

License: MIT, see LICENSE
]##
import std/files
import std/logging
import std/os

import common
import dbif_sqlite as db
import progress


type
  optsrem = tuple[f_apply: bool, f_quiet: bool]


proc dump(src, dst: common.file_info, f: bool): void =
    let st = if f: "!: " else: ".: "
    let (d, s) = (dst.path.string, src.path.string)
    stdout.write("hardlink" & st & d & " <= " & s & "\n")


proc dump2(src, dst: common.file_info): void =
    let d = dst.path.string
    stdout.write("hardlink-: " & d & " (same inode, skipped)\n")


proc hardlink(tmp: db.DBInfo, src, dst: common.file_info,
              f_apply: bool): void =
    if src.inode == dst.inode:
        var wrk = dst
        common.mark_done(wrk)
        db.update(tmp, dst.uid, wrk)
        dump2(src, dst)
        return
    dump(src, dst, f_apply)
    var dst = dst

    if f_apply:
        files.removeFile(dst.path)
        os.createHardlink(src.path.string, dst.path.string)

        src.count += 1
        db.update(tmp, src.uid, src)

        dst.count = src.count
        dst.inode = src.inode
    common.mark_done(dst)
    db.update(tmp, dst.uid, dst)


proc run*(src: db.DBInfo, opts: optsrem): int =
    ##[ remove files and create hardlinks instead of them
    ]##
    var stat = progress.prog_stat2(f_quiet: opts.f_quiet)
    while true:
        let fis = db.get_removes(src)
        if len(fis) < 2:
            break
        let f0 = fis[0]
        for fi in fis[1 ..^ 1]:
            stat = progress.show_collect(fi.path, stat)
            hardlink(src, f0, fi, opts.f_apply)
    progress.end_collect(stat.f_quiet)

