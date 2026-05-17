##[ version.nim
=========================

License: MIT, see LICENSE
]##
when isMainModule:
  import std/algorithm
  import std/logging
  import std/osproc
  import std/streams
  import std/strutils

const
  ver* = 0
  maj* = 2
  min* = 1
  num* = 49
  hash* = "ac40b1a"


proc version_string*(): string =
    return $ver & "." & $maj & "." & $min & " - " & $num & "(" & hash & ")"


when isMainModule:
  proc parse_tag(src: string): tuple[ver, maj, min: int] =
    var vers: seq[tuple[ver, maj, min: int]]
    for tag in src.split("\n"):
        let tag = tag.strip()
        debug("found tag:" & tag)
        if not tag.startsWith("v"): continue
        debug("remove prefix: " & tag[1 ..^ 1])
        let tmp = tag[1 ..^ 1].split(".")
        debug("split ver,maj,min: " & $tmp)
        if len(tmp) != 3: continue
        let ver = try:   parseInt(tmp[0])
                  except ValueError: 99
        let maj = try:   parseInt(tmp[1])
                  except ValueError: 99
        let min = try:   parseInt(tmp[2])
                  except ValueError: 99
        vers.add((ver, maj, min))
    debug("got versions: " & $vers)
    if len(vers) < 1:
        return (0, 0, 0)
    vers.sort(proc(a, b: tuple[ver, maj, min: int]): int =
        let cv = cmp(a.ver, b.ver)
        if cv != 0: return cv
        let cj = cmp(a.maj, b.maj)
        if cj != 0: return cj
        return cmp(a.min, b.min))
    debug("latest version: " & $vers[^1])
    return vers[^1]


  proc main(): int =
    let opt = {poUsePath}
    let tags = osproc.execProcess("git", args = ["tag"], options=opt)
    let v = parse_tag(tags)
    if v == (0, 0, 0):
        echo("version was not found: " & tags)
        return 1
    warn("version is: " & $v)
    let nm0 = osproc.execProcess(
        "git", args = ["rev-list", "--count", "eb13af6...HEAD"], options=opt)
    let num = nm0.strip()
    let has = osproc.execProcess(
        "git", args = ["rev-parse", "--short", "HEAD"], options=opt)
    let hash = has.strip()
    warn("num and hash: " & $num & "-" & hash)
    let file = currentSourcePath
    let strm = newstringStream()
    let fp = newFileStream(file, fmRead)
    for line in fp.lines():
        let lin0 = line.strip()
        if   lin0.startsWith("ver* ="):
            strm.writeLine("  ver* = " & $v.ver)
        elif lin0.startsWith("maj* ="):
            strm.writeLine("  maj* = " & $v.maj)
        elif lin0.startsWith("min* ="):
            strm.writeLine("  min* = " & $v.min)
        elif lin0.startsWith("num* ="):
            strm.writeLine("  num* = " & $num)
        elif lin0.startsWith("hash* ="):
            strm.writeLine("  hash* = \"" & hash & "\"")
        else:
            strm.writeLine(line)
    fp.close()
    strm.setPosition(0)
    let fp2 = newFileStream(file, fmWrite)
    fp2.write(strm.readAll())
    fp2.close()
    return 0

  logging.addHandler(logging.newConsoleLogger())
  logging.setLogFilter(lvlNotice)
  system.quit(main())

