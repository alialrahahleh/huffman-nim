import bitops
import system
import strutils

const BUF_SIZE = 32

type
  Buffer32* = object
    buff: uint32
    cSize: int8 

proc add*(buffer: var Buffer32, bits: uint32, size: int8) =
  let shlsize = (BUF_SIZE - buffer.cSize) - size
  buffer.buff = bitor(buffer.buff, bits shl shlsize)
  inc buffer.cSize, size
  

proc size*(buff: Buffer32): int8 = buff.cSize

proc shift*(buffer: var Buffer32): uint8 =
  result = cast[uint8](bitand(buffer.buff shr 24, 0xFF))
  dec buffer.cSize, 8
  buffer.buff = buffer.buff shl 8
  return result

proc `$`*(buffer: Buffer32): string = toBin(cast[int32](buffer.buff), 32)

