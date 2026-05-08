##[ uuidv7.nim
=========================

License: MIT, see LICENSE
]##
import std/times
import std/random


proc init*(): void =
    ##[
    ]##
    randomize()


proc gen*(): array[16, uint8] =
    ##[
        - 1. get timestamp in msec
        - 2. store time to head
        - 3. store version and variant
        - 4. store random into tail
    ]##
    let now = int64(times.epochTime() * 1000.0)

    result[0] = uint8((now shr 40) and 0xff)
    result[1] = uint8((now shr 32) and 0xff)
    result[2] = uint8((now shr 24) and 0xff)
    result[3] = uint8((now shr 16) and 0xff)
    result[4] = uint8((now shr 8) and 0xff)
    result[5] = uint8(now and 0xff)

    result[6] = uint8(rand(0x0f) or 0x70)  # Version 7 (0111)
    result[7] = uint8(rand(0xff))
    result[8] = uint8(rand(0x3f) or 0x80)  # Variant 10xx (RFC 4122)

    for i in 9 .. 15:
        result[i] = uint8(rand(255))

