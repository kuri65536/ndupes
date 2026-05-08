##[ extract.nim
=========================

License: MIT, see LICENSE
]##
import std/os
import std/paths

import common as common


proc normalize_path(src: Path, f_abs: bool): Path =
    if f_abs:
        if src.isAbsolute():
            return src
        return src.absolutePath()
    if not src.isAbsolute():
        return src
    return src.relativePath(paths.getCurrentDir())


proc extract1*(src: Path, f_abs: bool): common.file_info =
    ##[
    ]##
    let src = normalize_path(src, f_abs)

    let fi = os.getFileInfo(src.string, false)
    if fi.isSpecial:
        return nil
    if fi.kind in {pcLinkToFile, pcLinkToDir}:
        return nil

    return common.file_info(
        size: fi.size,
        count: fi.linkCount,
        inode: fi.id.file,
        path: src,
    )

