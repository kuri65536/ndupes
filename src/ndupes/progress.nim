##[ progress.nim
=========================

License: MIT, see LICENSE
]##
import std/paths
import std/terminal
import std/times


type
    prog_stat* = tuple[update: bool, tty, filepos: int, cputime: float]


let
    thsec = (tty: 2.0,
             log: 10.0, )
    thsize = (large_file:  1000_000,
              large_delta: 1000_000,
              pct_tty: 2,
              pct_log: 10, )


proc update_timing_time(tty: int, prev: float): (bool, float) =
    let cur = times.cpuTime()
    if prev < 1:
        return (true, cur)
    let delta = cur - prev
    if tty == 2 and delta > thsec.tty:
        return (true, cur)
    if tty == 1 and delta > thsec.log:
        return (true, cur)
    return (false, prev)


proc update_timing(cur, size: int, prev: prog_stat): prog_stat =
    let tty = block:
        if prev.tty > 0:              prev.tty
        elif terminal.isatty(stderr): 1
        else:                         2
    let (f1, new_time) = update_timing_time(tty, prev.cputime)
    if f1:
        return (true, tty, prev.filepos, new_time)

    if prev.filepos < 1:
        return (true, tty, cur, new_time)

    let delta = cur - prev.filepos
    if tty == 1 and delta > (size * thsize.pct_log) div 100:
        return (true, tty, cur, new_time)
    elif tty == 1:
        return (false, tty, prev.filepos, prev.cputime)

    if size > thsize.large_file and delta > thsize.large_delta:
        return (true, tty, cur, new_time)
    if delta > (size * thsize.pct_tty) div 100:
        return (true, tty, cur, new_time)
    return (false, tty, prev.filepos, prev.cputime)


proc show_hash*(src: Path, cur, size: int, prev: prog_stat): prog_stat =
    ##[ show progress in hash calculation
    ]##
    result = update_timing(cur, size, prev)
    if not result.update:
        return

    let msg = src.string
    stderr.write(msg & "\n")
