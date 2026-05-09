##[ options_macro.nim
=========================

License: MIT, see LICENSE
]##
import logging
import strutils
import tables
import macros


type
  tuple_parses = tuple[short: char,
                       long, fallback: string]


proc append(tbl: var Table[string, seq[string]], p, value: string): void =
    if tbl.contains(p):
        tbl[p] = tbl[p] & @[value]
    else:
        tbl[p] = @[value]


proc parse*(args: seq[string], defs: Table[string, tuple_parses]
           ): Table[string, seq[string]] =
            # tuple[s: char, l, f: string]]
    ##[ parses command line options to the table.
    ]##
    var nxt = ""
    for arg in args:
        if nxt != "":
            append(result, nxt, arg)
            nxt = ""
            continue
        var f_proc = false
        for key, (s, l, f) in defs:
            if arg == '-' & s: discard
            elif arg == l:     discard
            else:              continue
            if len(f) < 1:
                nxt = key
            else:
                append(result, key, f)
            f_proc = true; break
        if not f_proc:
            append(result, "", arg)


macro parse_all*(obj: untyped, args: typed, parsers: varargs[untyped]): void =
    ##[ this macro will be expanded to:

        ```
        let definitions = {a: b, c: d, ...}.toTable()
        let prms = parse(args, definitions)
        result.(a.sym) = a.fn(getOrDefault(prms, a.id, @[]))
        result.(b.sym) = b.fn(getOrDefault(prms, b.id, @[]))
        result.(c.sym) = c.fn(getOrDefault(prms, c.id, @[]))
        ...
        ```
    ]##
    template short(a: NimNode): NimNode = a[0]
    template long(a: NimNode): NimNode = a[1]
    template fallback(a: NimNode): NimNode = a[2]
    template fn(a: NimNode): NimNode = a[3]
    template sym(a: NimNode): NimNode = a[4]
    template fn_str(a: NimNode): NimNode = a

    var (defs, prms) = (ident"definitions", ident"prms")

    # make the table: {"fn1": (short:' ', long:"", fallback:""),
    #                  "fn2": (short:' ', long:"", fallback:""), ...}
    var tuples = newTree(nnkTableConstr)
    for i in parsers:
        if isNil(i.fn): continue
        if i.long.strVal.len < 1: continue
        tuples.add(newColonExpr(
            fn_str(i.long),
            newNimNode(nnkTupleConstr
                       ).add(newColonExpr(ident("short"), i.short)
                       ).add(newColonExpr(ident("long"), i.long)
                       ).add(newColonExpr(ident("fallback"), i.fallback)
                       )
        ))
    result = newStmtList()
    # let definitions = {...}.toTable()
    result.add(newLetStmt(defs, newCall(bindSym"toTable", tuples)))
    # let prms = parse(args, definitions)
    result.add(newLetStmt(prms, newCall(bindSym"parse", args, defs)))
    for i in parsers:
        if isNil(i.fn):
            # obj.sym = prms.getOrDefault("", @[])
            let c0 = newCall(bindSym"getOrDefault",
                             prms, newLit(""), newLit(newSeq[string]()))
            result.add(newAssignment(newDotExpr(obj, i.sym), c0))
            continue
        if i.long.strVal.len < 1:
            # fn(prms.getOrDefault("", @[]))
            # obj.sym = fn(...)
            let c2 = newCall(i.fn,
                    newDotExpr(obj, i.sym),
                    newCall(bindSym"getOrDefault",
                            prms, newLit(""), newLit(newSeq[string]())
                    )
                )
            result.add(newAssignment(newDotExpr(obj, i.sym), c2))
            continue
        # fn(obj.sym, prms.getOrDefault(i.long, @[]))
        let cl = newCall(i.fn,
                newDotExpr(obj, i.sym),
                newCall(bindSym"getOrDefault",
                        prms, fn_str(i.long), newLit(newSeq[string]())
                )
            )
        # obj.sym = fn(...)
        result.add(newAssignment(newDotExpr(obj, i.sym), cl))


proc parse_verbosity*(src: int, args: seq[string]): int =
    ##[ setups the verbosity of the app console
    ]##
    let lvl = block:
      if len(args) < 1:
        lvlWarn
      else:
        let n = try:   parseInt(args[0])
                except ValueError: -1
        if   n >= 70:  lvlAll
        elif n >= 60:  lvlFatal
        elif n >= 50:  lvlError
        elif n >= 40:  lvlWarn
        elif n >= 30:  lvlNotice
        elif n >= 20:  lvlInfo
        elif n >= 10:  lvlDebug
        elif n >= 0:   lvlAll
        else:
          case args[0].toLower():
          of "debug": lvlDebug
          of "info": lvlInfo
          of "information": lvlInfo
          of "notice": lvlNotice
          of "error": lvlError
          of "fatal": lvlFatal
          of "warning": lvlWarn
          of "warn": lvlWarn
          else:      lvlWarn
    if src != int(lvl):
        result = int(lvl)
    if len(logging.getHandlers()) < 1:
        logging.addHandler(logging.newConsoleLogger())
    logging.setLogFilter(lvl)


proc parse_true*(src: bool, args: seq[string]): bool =
    ##[
    ]##
    return len(args) > 0


proc parse_false*(src: bool, args: seq[string]): bool =
    ##[
    ]##
    return len(args) < 1


proc parse_int*(src: int, args: seq[string]): int =
    ##[
    ]##
    for i in args:
        let tmp = try: parseInt(i)
                  except ValueError: continue
        return tmp
    return src


proc parse_str*(src: string, args: seq[string]): string =
    ##[
    ]##
    if len(args) > 0:
        return args[0]
    return src


proc parse_strs*(src: seq[string], args: seq[string]): seq[string] =
    ##[
    ]##
    result = src
    for i in args:
        result.add(i)


when isMainModule:
  template o(a, b: untyped) =
    echo(a & "c1: " & b.c1 & ", c2:" & $b.c2 & ", args:" & $b.arg)
    

  proc test1(): void =
    var tmp = (c1: "", c2: false, arg: @[""])  # testvar()
    o("before: ", tmp)
    #ar tmp = testvar()
    parse_all(tmp, @["test", "--c1", "a", "--c2", "abc", "bcd"],
        (' ', "--c1", "", parse_str, c1),
        (' ', "--c2", "1", parse_true, c2),
        (' ', "", "", parse_strs, arg),
    )
    o("after : ", tmp)


  block:
    test1()

