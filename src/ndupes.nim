##[ ndupes.nim
=========================

License: MIT, see LICENSE for details
]##
import os
import system

import ndupes/app


proc main(): void =
    var args: seq[string]
    for i in 1 .. os.paramCount():
        args.add(os.paramStr(i))
    system.quit(app.run(args))


when isMainModule:
    main()

