##[ options.nim
=========================

License: MIT, see LICENSE
]##
import std/paths
import std/strutils

import common
import options_macro


type
  run_options* = enum
    until_hash

  Options* = ref object of RootObj
    n_method*: common.calc_method
    paths*: seq[Path]
    size*: int
    tmpdb*: Path
    runflags*: set[run_options]


proc parse_flag(src: set[run_options], opts: seq[string]): set[run_options] =
    var src = src
    for i in low(run_options) .. high(run_options):
        if opts.contains($i):
            src.incl(i)
            return src
    return src


proc parse_method(src: common.calc_method, opts: seq[string]
                  ):   common.calc_method =
    if len(opts) < 1:
        return src
    return case opts[0].toLower():
           of "sha256": common.calc_method.method_sha256
           of "md5":    common.calc_method.method_md5
           else:  src


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
        size: 1_000_000,
        tmpdb: Path("ndupes.db"),
    )
    options_macro.parse_all(result, args,
        (' ', "--until-hash", $until_hash, parse_flag, runflags),
        (' ', "--db", "", parse_path, tmpdb),
        (' ', "--method", "", parse_method, n_method),
        (' ', "--size", "", parse_int, size),
        (' ', "", "", parse_paths, paths),
    )

