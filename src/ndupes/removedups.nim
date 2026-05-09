##[ removedups.nim
=========================

License: MIT, see LICENSE
]##
import std/files
import std/logging
import std/os

import common
import dbif_sqlite as db


type
  optsrem = tuple[f_apply: bool]


proc dump(src, dst: common.file_info, f: bool): void =
    let st = if f: "!: " else: ".: "
    let (d, s) = (dst.path.string, src.path.string)
    stdout.write("hardlink" & st & d & "<=" & s & "\n")


proc hardlink(tmp: db.DBInfo, src, dst: common.file_info,
              f_apply: bool): void =
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
    while true:
        let fis = db.get_removes(src)
        if len(fis) < 2:
            break
        let f0 = fis[0]
        for fi in fis[1 ..^ 1]:
            hardlink(src, f0, fi, opts.f_apply)

