import "../src/huffman"
import unittest
import strutils
import strformat
import sugar
import sequtils
import streams

suite "Test huffman encoding":
  setup:
    let textToEncode = "mmm ko is lp loooos"
    let encoder = createEncoder(textToEncode)
  
  test "test encodeding":
    check(encoder.encodeStr(textToEncode) ==  @[6, 6, 6, 2, 62, 0, 2, 126, 14, 2, 30, 127, 2, 30, 0, 0, 0, 0, 14])

  test "test decoding against static code":
    let frt = toSeq(join(@[6, 6, 6, 2, 62, 0, 2, 126, 14, 2, 30, 127, 2, 30, 0, 0, 0, 0, 14].map(x => &"{x:b}"), ""))
    check(encoder.decodeStr(frt) == textToEncode)

  test "test decoding against text":
    let frt = toSeq(join(encoder.encodeStr(textToEncode).map(x => &"{x:b}"), ""))
    check(encoder.decodeStr(frt) == textToEncode)

  test "test encoding stream":
    let txtStream = newStringStream(textToEncode)
    var res = ""
    for x in encoder.encodeStream(txtStream):
      let (bitNum, _) = x
      res.add($bitNum)
    check(res == "6662620212614230127230000014")

  test "test encoding/decoding stream":
    let txtStream = newStringStream(textToEncode)
    let outStream = newStringStream("")
    var buffer = ""
    var charNumbers = 0
    for item in encoder.encodeStream(txtStream):
      let (x,_) = item
      buffer.add(&"{x:b}")
      inc(charNumbers)
      if buffer.len > 7:
        outStream.write(fromBin[int8](buffer[0..7]))
        buffer.delete(0, 7)
    if buffer.len > 0:
      outStream.write(
        fromBin[int8](buffer[0..^1]) shl (8 - buffer.len)
        )

    outStream.setPosition(0)
    outStream.flush()

    var res: seq[char] = @[]
    for y in encoder.decodeStream(outStream):
      dec(charNumbers)
      res.add(y)
      if charNumbers == 0:
        break;

    check(join(res, "") == textToEncode)





  
