##[ options.nim
=========================

License: MIT, see LICENSE
]##
import std/paths

import options_macro


type
  Options* = ref object of RootObj
    paths*: seq[Path]
    tmpdb*: Path


proc parse_path(src: Path, opts: seq[string]): Path =
    if len(opts) > 0:
        return Path(opts[0])
    return src


proc parse_paths(src: seq[Path], opts: seq[string]): seq[Path] =
    result = src
    for i in opts:
        result.add(Path(i))


proc parseargs*(src: openarray[string]): Options =
    var args: seq[string]
    for i in src:
        args.add(i)
    result = Options(
        tmpdb: Path("ndupes.db"),
    )
    options_macro.parse_all(result, args,
        (' ', "--db", "", parse_path, tmpdb),
        (' ', "", "", parse_paths, paths),
    )

