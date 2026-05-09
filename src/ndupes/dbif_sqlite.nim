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


proc uid2hex(s: common.uid_type): string =
    for n, i in array[16, uint8](s):
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
    let id = uid2hex(uid_type(uid.gen()))
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


proc update*(db: DBInfo, uid: uid_type, src: common.file_info): void =
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


proc get_unhash*(db: DBInfo, size: int): common.file_info =
    ##[ find the unhash record from `db`

        for reduce memory usage, this func just get one record.
    ]##
    let hash = block:
        var tmp: array[32, uint8]
        hash2hex(tmp)
    #cho("get_unhash:" & $size & "-" & hash)
    let qry = """
        SELECT * FROM file
        WHERE size >= ?
          AND hash = ?
          AND error < 1
          AND size IN (
            SELECT size FROM file GROUP BY size
            HAVING COUNT(*) > 1
          )
        ORDER BY size
        LIMIT 1
    """
    if not dbc.tryExec(db.conn, dbc.sql(qry), size, hash):
        try:
            dbc.dbError(db.conn)
        except DBError:
            error(getCurrentExceptionMsg())
        return nil
    let x = dbc.getRow(db.conn, dbc.sql(qry), size, hash)
    if len(x) < 1 or len(x[0]) < 1:
        return nil
    echo("get_unhash:got" & $x)
    return common.newFileInfo(x)


proc get_removes*(db: DBInfo): seq[common.file_info] =
    ##[ - get unproc size and hash
    ]##
    let qry1 = """
        SELECT size, hash FROM file
        WHERE error < 1 and done < 1
        GROUP BY size, hash
        HAVING COUNT(*) > 1
        limit 1
    """
    echo("get_removes:find doubled files...")
    if not dbc.tryExec(db.conn, dbc.sql(qry1)):
        try:
            dbc.dbError(db.conn)
        except DBError:
            error(getCurrentExceptionMsg())
        return @[]
    let size_hash = dbc.getRow(db.conn, dbc.sql(qry1))
    if len(size_hash) < 1:
        return @[]
    let size = size_hash[0]
    let hash = size_hash[1]
    if len(size) < 1 or len(hash) < 1:
        return @[]
    echo("get_removes:found doubled..." & size & "-" & hash)

    let qry2 = """
        SELECT * FROM file
        WHERE size = ? and hash = ?
    """
    result = @[]
    for x in dbc.fastRows(db.conn, dbc.sql(qry2), size, hash):
        let fi = common.newFileInfo(x)
        result.add(fi)


proc get_all*(db: DBInfo, uid: common.uid_type): common.file_info =
    ##[ - get unproc size and hash
    ]##
    let uid = uid2hex(uid)
    let qry1 = """
        SELECT * FROM file
        WHERE uid > ?
        ORDER BY uid
        ASC limit 1;
    """
    if not dbc.tryExec(db.conn, dbc.sql(qry1), uid):
        try:
            dbc.dbError(db.conn)
        except DBError:
            error(getCurrentExceptionMsg())
        return nil
    let row = dbc.getRow(db.conn, dbc.sql(qry1), uid)
    if len(row) < 1 or len(row[0]) < 1:
        return nil
    return common.newFileInfo(row)

