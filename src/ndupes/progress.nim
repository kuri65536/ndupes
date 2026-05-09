##[ progress.nim
=========================

License: MIT, see LICENSE
]##
import std/logging
import std/paths
import std/terminal
import std/times
import std/strutils


type
  prog_stat* = object of RootObj
    update: bool
    filepos: int
    tty, width: int
    cputime: float

let
    tty_none = 0
    tty_term = 1
    tty_file = 2
    tty_width_default = 80
    thsec = (tty: 2.0,
             log: 10.0, )
    thsize = (large_file:  1000_000,
              large_delta: 1000_000,
              pct_tty: 2,
              pct_log: 10, )


proc terminal_info(): tuple[ttytype, ttywidth: int] =
    if not terminal.isatty(stderr):
        return (tty_file, tty_width_default)
    let width = terminal.terminalWidth()
    if width < 1:
        return (tty_term, tty_width_default)
    debug("progress: got width" & $width)
    return (tty_term, width)


proc update_timing_time(tty: int, cur, prev: float): (bool, float) =
    if prev < 1:
        return (true, cur)
    let delta = cur - prev
    if tty == tty_term and delta > thsec.tty:
        return (true, cur)
    if tty == tty_file and delta > thsec.log:
        return (true, cur)
    return (false, prev)


proc update_timing(cur, size: int, prev: prog_stat): prog_stat =
    result = prev
    let curtime = times.cpuTime()
    if prev.tty <= tty_none:
        (result.tty, result.width) = terminal_info()
        result.update = true; return

    let tty = prev.tty
    let (f1, new_time) = update_timing_time(tty, curtime, prev.cputime)

    proc update(): prog_stat =
        result = prev
        (result.update, result.filepos, result.cputime) = (true, cur, new_time)

    if f1:
        return update()

    if prev.filepos < 1:
        return update()

    let delta = cur - prev.filepos
    if tty == tty_file and delta > (size * thsize.pct_log) div 100:
        return update()
    elif tty == tty_file:
        result.update = false; return result

    if size > thsize.large_file and delta > thsize.large_delta:
        return update()
    if delta > (size * thsize.pct_tty) div 100:
        return update()
    result.update = false; return result


proc show_hash*(src: Path, cur, size: int, prev: prog_stat): prog_stat =
    ##[ show progress in hash calculation
    ]##
    result = update_timing(cur, size, prev)
    if not result.update:
        return

    let dpct = (cur * 1000) div size
    var pct = "(" & align($(dpct div 10), 3) & "." & $(dpct mod 10) & "%) "

    var msg = $size
    msg = align($cur, len(msg)) & "/" & msg & pct

    let n_len = result.width - len(msg) - 1
    var fn = src.string
    if len(fn) >= n_len:
        fn = fn[^n_len .. ^1]
        fn = "..." & fn[3 ..^ 1]

    msg &= fn
    if result.tty == tty_file:
        stderr.write(msg & "\n")
    else:
        stderr.write("\r\e[K" & msg)
        if dpct >= 1000:
            stderr.write("\n")

