##[ calchash.nim
=========================

License: MIT, see LICENSE
]##
import common


type
  optscalc* = tuple[n: common.calc_method, size: int]


proc run*(src: db.DBInfo, opts: optscalc): int =
    ##[ calculate hashes with files in DB.

        for reducing memory usage,

        - get just one file from DB per loop
        - calculate hash with blocksize reading
    ]##
    return 0

