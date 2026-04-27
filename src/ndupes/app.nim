##[ app.nim
=========================

License: MIT, see LICENSE
]##
import std/paths

import options


type
  path_info = tuple[f: Path]


iterator walk(paths: openarray[Path]): path_info =
    discard


proc run*(args: openarray[string]): int =
    ##[
    ]##
    let opts = options.parseargs(args)
    for pi in walk(opts.paths):
        discard


when isMainModule:
    discard

