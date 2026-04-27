##[ options.nim
=========================

License: MIT, see LICENSE
]##
import std/paths


type
  Options* = ref object of RootObj
    paths*: seq[Path]


proc parseargs*(src: openarray[string]): Options =
    return Options(
    )

