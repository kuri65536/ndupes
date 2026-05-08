##[ common.nim
=========================

License: MIT, see LICENSE
]##
import std/logging
import std/paths
import std/strutils


type
  calc_method* = enum
    method_md5
    method_sha256

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


proc equals*(a, b: file_info): bool =
    ##[ compare two file_info
    ]##
    debug("scan:equals:" & a.path.string & " vs " & b.path.string)
    if a.path != b.path:
        echo("!= path"); return false
    debug("scan:equals:" & $a.inode & " vs " & $b.inode)
    if a.inode != b.inode:
        echo("!= inode"); return false
    if a.size != b.size:
        echo("!= size"); return false
    if a.count != b.count:
        echo("!= count"); return false
    if a.head != b.head:
        echo("!= head"); return false
    if a.tail != b.tail:
        echo("!= tail"); return false
    return true



