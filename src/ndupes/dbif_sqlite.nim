##[ dbif_sqlite.nim
=========================

License: MIT, see LICENSE
]##
import std/db_sqlite as dbc
import std/logging
import std/paths
import std/strutils

import common as common
import uuidv7 as uid


type
  DBInfo* = ref object of RootObj
    conn: dbc.DbConn


proc uid2hex(s: array[16, uint8]): string =
    for n, i in s:
        if [6, 9].contains(n): result &= "-"
        result &= toHex(i, 2)


proc hash2hex(s: array[32, uint8]): string =
    for n, i in s:
        if [8, 16, 24].contains(n): result &= "-"
        result &= toHex(i, 2)


proc has_table*(conn: dbc.DbConn): bool =
    let qry = """
        SELECT * FROM sqlite_master WHERE name = "file"
        """
    for x in dbc.fastRows(conn, dbc.sql(qry)):
        return true
    dbc.exec(conn, sql"""
        create table file (
            uid blob primary key,
            inode integer,
            size integer,
            lcnt integer,
            chrh integer,
            chrt integer,
            hash blob,
            error integer,
            done integer,
            path text not null
        ) without rowid""")
    dbc.exec(conn, dbc.sql"""
        create index idx_file_size_hash ON file (size, hash);
        create index idx_file_hash ON file (hash);
        create index idx_file_path ON file (path);
        """)


proc open*(src: Path): DBInfo =
    ##[
    ]##
    uid.init()
    let c = dbc.open(src.string, "", "", "")
    discard has_table(c)
    return DBInfo(conn: c)


proc close*(src: DBInfo): void =
    ##[
    ]##
    dbc.close(src.conn)


proc save*(db: DBInfo, src: var common.file_info): void =
    ##[ save new file record
    ]##
    let id = uid2hex(uid.gen())
    let hs = hash2hex(src.hash)
    dbc.exec(db.conn, sql"""
        INSERT INTO file values(
            ?, ?, ?, ?,
            ?, ?,
            ?, ?, ?, ?)""",
        id, src.inode, src.count, src.size,
        src.head, src.tail,
        hs, src.error, src.done, src.path.string
    )


proc update*(db: DBInfo, uid: array[16, uint8], src: common.file_info): void =
    ##[ update DB from new value

        no update with uid and path
    ]##
    dbc.exec(db.conn, sql"""
        update file set inode = ?, size = ?, lcnt = ?,
                        chrh = ?, chrt = ?, hash = ?,
                        error = ?, done = ?
               where uid = ?
        """,
        src.inode, src.size, src.count,
        src.head, src.tail, hash2hex(src.hash),
        src.error, src.done,
        uid2hex(uid)
    )


proc load*(db: DBInfo, f: Path): common.file_info =
    ##[ load a record from `db` with `path` as the key
    ]##
    let qry = "SELECT * FROM file WHERE path = ?"
    debug("scan:get-row:select: " & f.string)
    if not dbc.tryExec(db.conn, dbc.sql(qry), f.string):
        try:
            dbc.dbError(db.conn)
        except DBError:
            error(getCurrentExceptionMsg())
        return nil
    let x = dbc.getRow(db.conn, dbc.sql(qry), f.string)
    if len(x) < 1 or len(x[0]) < 1:
        return nil
    debug("scan:get-row:got: " & $x)
    return common.newFileInfo(x)

