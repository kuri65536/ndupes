##[ dbif_sqlite.nim
=========================

License: MIT, see LICENSE
]##
import std/db_sqlite as dbc
import std/paths


type
  DBInfo* = ref object of RootObj
    conn: dbc.DbConn


proc open*(src: Path): DBInfo =
    ##[
    ]##
    let c = dbc.open(src.string, "", "", "")
    return DBInfo(conn: c)


proc close*(src: DBInfo): void =
    ##[
    ]##
    dbc.close(src.conn)

