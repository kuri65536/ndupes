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



