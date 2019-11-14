import "../src/buffer"

import unittest
import strutils
import strformat
import sugar
import sequtils
import streams

suite "Test huffman encoding":
  setup:
    var buffer = Buffer32()
  
  test "test add to buffer":
    buffer.add(3, 2)
    check(buffer.size() == 2)

  test "test top 8":
    buffer.add(0xF8F7, 16)
    buffer.add(0xF3F2, 16)
    check(buffer.size() == 32)
    check(buffer.shift() == 0xF8)
    check(buffer.shift() == 0xF7)
    check(buffer.shift() == 0xF3)
    check(buffer.shift() == 0xF2)

  test "test non even bits":
    buffer.add(3, 2)
    buffer.add(3, 2)
    buffer.add(2, 2)
    buffer.add(3, 2)
    buffer.add(3, 2)
    check(buffer.size() == 10)
    check(buffer.shift() == 0xFB)
    check(buffer.size() == 2)
    check(buffer.shift() == 0xC0)



  
