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
        # fn(prms.getOrDefault(i.long, @[]))
        let cl = newCall(i.fn,
                newCall(bindSym"getOrDefault",
                        prms, fn_str(i.long), newLit(newSeq[string]())
                )
            )
        # obj.sym = fn(...)
        result.add(newAssignment(newDotExpr(obj, i.sym), cl))


proc parse_verbosity*(args: seq[string]): int =
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
    logging.addHandler(logging.newConsoleLogger())
    logging.setLogFilter(lvl)


proc parse_true*(args: seq[string]): bool =
    ##[
    ]##
    return len(args) > 0


proc parse_false*(args: seq[string]): bool =
    ##[
    ]##
    return len(args) < 1

