##[ common.nim
=========================

License: MIT, see LICENSE
]##
import std/logging
import std/paths
import std/strutils


type
  file_info* = ref object of RootObj
    uid*: array[16, uint8]
    size*: int64
    count*: int
    inode*: int64
    head*: int32
    tail*: int32
    hash*: array[32, uint8]
    error*: int8
    done*: int8
    path*: Path


proc get_hex(buf: var openarray[uint8], src: string): void =
    echo("parse..." & src)
    var i = 0
    var tmp = ""
    for ch in src:
        if ch == '-':
            continue
        tmp &= $ch
        if len(tmp) < 2:
            continue
        buf[i] = uint8(parseHexInt("0x" & tmp))
        i += 1
        tmp = ""


proc newFileinfo*(src: openarray[string]): file_info =
    ##[ restore file_info from SQL data
    ]##
    result = file_info(
        inode: parseInt(src[1]),
        size: parseInt(src[2]),
        count: parseInt(src[3]),
        head: int32(parseInt(src[4])),
        tail: int32(parseInt(src[5])),
        error: int8(parseInt(src[7]) and 0x7F),
        done: int8(parseInt(src[8]) and 0x7F),
        path: Path(src[9]),
    )
    get_hex(result.uid, src[0])
    get_hex(result.hash, src[6])



