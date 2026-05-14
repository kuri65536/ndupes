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
    f_quiet*: bool

  prog_stat2* = object of RootObj
    tty, width: int
    count, prev_count: int
    cputime, starttime: float
    f_quiet*: bool

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
    thcollect = (files: 100,
                 sec: 2.0, )


proc initProgStat2*(f_quiet: bool): prog_stat2 =
    return prog_stat2(starttime: times.cpuTime(),
                      f_quiet: f_quiet, )


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
    if prev.f_quiet:
        result.update = false; return result

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


proc truncate(prefix, path: string, termwidth: int): string =
    let n_len = termwidth - len(prefix) - 1

    result = path
    if len(result) >= n_len:
        result = path[^n_len .. ^1]
        result = "..." & path[3 ..^ 1]

    return prefix & result


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
    msg = truncate(msg, src.string, result.width)

    if result.tty == tty_file:
        stderr.write(msg & "\n")
    else:
        stderr.write("\r\e[K" & msg)
        if dpct >= 1000:
            stderr.write("\n")


proc ellapsed(cur, origin: float): string =
    let delta0 = int64(cur - origin)
    let days = delta0 div (24 * 3600)
    let delta1 = delta0 mod (24 * 3600)
    let hour = delta1 div 3600
    let delta2 = delta1 mod 3600
    let mins = delta2 div 60
    let secs = delta2 mod 60
    result = ""
    if days > 0:
        result &= $days & "d "
    result &= align($hour, 2, '0') & ":" &
              align($mins, 2, '0') & ":" & align($secs, 2, '0')


proc show_collect*(src: Path, prev: prog_stat2): prog_stat2 =
    ##[ show progress in collect files
    ]##
    result = prev
    result.count += 1

    if prev.f_quiet:
        return prev

    let cur = times.cpuTime()
    if prev.starttime < 1:  # first time
        (result.tty, result.width) = terminal_info()
        result.starttime = cur

    if cur - result.cputime < thcollect.sec and
       result.count != 1 and
       result.count - result.prev_count < thcollect.files:
        return result

    let time = "(" & ellapsed(cur, result.starttime) & ")"
    let count = "-" & align($result.count, 5) & " "
    let msg = truncate(time & count, src.string, result.width)
    if result.tty == tty_file:
        stderr.write(msg & "\n")
    else:
        stderr.write("\r\e[K" & msg)

    (result.prev_count, result.cputime) = (result.count, cur)


proc end_collect*(stat: prog_stat2, pfx: string): void =
    let cur = times.cpuTime()
    stdout.write(pfx & "finished (" & ellapsed(cur, stat.starttime) & ")\n")
    if stat.f_quiet:
        return
    stderr.write("\n")

