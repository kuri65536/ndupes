##[ removedups.nim
=========================

License: MIT, see LICENSE
]##
import common
import dbif_sqlite as db


type
  optsrem = tuple[f_apply: bool]


proc run*(src: db.DBInfo, opts: optsrem): int =
    ##[ remove files and create hardlinks instead of them
    ]##
    while true:
        let fis = db.get_removes(src)

