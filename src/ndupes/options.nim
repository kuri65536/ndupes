##[ options.nim
=========================

License: MIT, see LICENSE
]##
import std/logging
import std/paths
import std/strutils

import common
import options_macro
import version


type
  run_options* = enum
    apply
    dump
    until_hash

  Options* = ref object of RootObj
    dumpflags*: set[dump_options]
    n_method*: common.calc_method
    paths*: seq[Path]
    size*: int
    tmpdb*: Path
    runflags*: set[run_options]
    verbosity*: int


proc parse_flag(src: set[run_options], opts: seq[string]): set[run_options] =
    var src = src
    for i in low(run_options) .. high(run_options):
        if opts.contains($i):
            warn("option found for " & $i & ":" & $opts)
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


proc parse_version(src: set[run_options], opts: seq[string]): set[run_options] =
    if len(opts) < 1:
        return src
    stdout.write("ndupes, duplicate file eliminator: " & version.version_string())
    system.quit(1)


proc parseargs*(src: openarray[string]): Options =
    var args: seq[string]
    for i in src:
        args.add(i)
    result = Options(
        size: 1_000_000,
        tmpdb: Path("ndupes.db"),
    )
    options_macro.parse_all(result, args,
        ('V', "--version", "true", parse_version, runflags),
        ('v', "--verbosity", "", parse_verbosity, verbosity),
        (' ', "--vv", "30", parse_verbosity, verbosity),
        (' ', "--vvv", "20", parse_verbosity, verbosity),
        (' ', "--vvvv", "10", parse_verbosity, verbosity),
        (' ', "--vvvvv", "0", parse_verbosity, verbosity),
        (' ', "--apply", $apply, parse_flag, runflags),
        (' ', "--dump", $dump, parse_flag, runflags),
        (' ', "--until-hash", $until_hash, parse_flag, runflags),
        (' ', "--db", "", parse_path, tmpdb),
        (' ', "--method", "", parse_method, n_method),
        (' ', "--size", "", parse_int, size),
        (' ', "", "", parse_paths, paths),
    )

