# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
import sequtils
import sugar
import algorithm
import bitops
import strformat
import streams
import strutils
from strutils import join


type 
  NodeKind = enum Fork, Leaf
  Node = ref object 
    case kind: NodeKind
      of Fork: f:  tuple[weight: int, left: Node, right: Node, chList: seq[char]]
      of Leaf: l:  tuple[weight: int, ch: char]

proc weight(nd: Node): int =
  case nd.kind:
    of Fork: nd.f.weight
    of Leaf: nd.l.weight

proc `<`(a, b: Node): bool = weight(a) < weight(b)

proc chList(nd: Node): seq[char] =
  case nd.kind:
    of Fork: nd.f.chList
    of Leaf: @[nd.l.ch]

proc isSingle(list: seq[Node]): bool = len(list) == 1

proc myCmp(x, y: Node): int =
  if weight(x) < weight(y) : -1 else: 1

proc combine(list: seq[Node]): seq[Node] =
  let first  = list[0]
  let second = list[1]
  let f = Node(kind: Fork, f: (
    weight: first.weight + second.weight,
    left: first, right: second,
    chList: concat(first.chList, second.chList)))
  var r = concat(@[f], list[2..^1])
  var p: seq[Node] = @[]
  var added = false
  for x in r:
    if weight(x) < weight(f) or added == true:
      p.add(x)
    else:
      added = true
      p.add(f)
  return p


proc left(n: Node): Node =
  return n.f.left

proc right(n: Node): Node =
  return n.f.right

proc freq(list: seq[char]): seq[(char, int)] =
  let ls = list.deduplicate()
  return ls.map(s => (s, list.count(s)))

proc print(list: Node, depth: uint = 0) =
  if list.kind == Leaf:
    echo(&"Leaf {chlist(list)}")
    return
  echo &"(Fork [{chList(list)}] Left"
  print(list.left, depth + 1)
  echo &"Right"
  print(list.right, depth + 1)
  echo ")"

proc encode(root: Node, c: char): int =
  var cNode = root
  var path = 0 
  while true:
    let leftNum = bitor(path shl 1, 1)
    if cNode.kind == Leaf:
      return path
    if c in cNode.left.chList:
      path = leftNum
      cNode = cNode.left
    elif c in cNode.right.chList:
      path = path shl 1
      cNode = cNode.right

iterator encodeStream*(root: Node, stream: Stream): int =
  var cNode = root
  var path = 0 
  while not stream.atEnd():
    let c = stream.readChar()
    while true:
      let leftNum = bitor(path shl 1, 1)
      if cNode.kind == Leaf:
        yield path
        path = 0
        cNode = root
        break
      if c in cNode.left.chList:
        path = leftNum
        cNode = cNode.left
      elif c in cNode.right.chList:
        path = path shl 1
        cNode = cNode.right


iterator decodeStream(root: Node, stream: Stream) : char  =
  var pNode = root
  while not stream.atEnd():
    let x = stream.readInt8
    var cnt = 8 
    while cnt > -1:
      if bitand(x shr cnt, 1) == 1:
        pNode = pNode.left
      else:
        pNode = pNode.right

      if pNode.kind == Leaf:
        yield pNode.l.ch
        pNode = root
      dec(cnt)


iterator decodeIter(root: Node, p: seq[char]) : char  =
  var pNode = root
  for x in p:
    if x == '1':
      pNode = pNode.left
    else:
      pNode = pNode.right

    if pNode.kind == Leaf:
      yield pNode.l.ch
      pNode = root


proc decodeStr*(root: Node, p: seq[char]) : seq[char] =
  var r: seq[char]
  var pNode = root
  for x in p:
    if x == '1':
      pNode = pNode.left
    else:
      pNode = pNode.right

    if pNode.kind == Leaf:
      r.add(pNode.l.ch)
      pNode = root
  return r

proc encodeChr(list: Node, c: char): int =
  return encode(list, c)


proc toLeaf(freq: seq[(char, int)]): seq[Node] =
  freq.map(s => Node(kind: Leaf, l: (weight: s[1], ch: s[0])))
  
proc createEncoder*(chList: string): Node =
  let chList = toSeq(chList.items)
  var x = sorted(toLeaf(freq(chList)), myCmp)
  while not isSingle(x):
    x = combine(x)
  return x[0]

proc encodeStr*(node: Node, str: string): seq[int] =
  let s = toSeq(str.items)
  return s.map(x => node.encodeChr(x))

iterator chunk32(ch: seq[char]): seq[char] =
  var pos = 0 
  var en = pos + 31
  while true:
    if pos > ch.len:
      break
    if en >= ch.len:
      yield ch[pos..^1]
    else:
      yield ch[pos..en]
    inc pos, 32
    en = pos + 31


when isMainModule:
  let encoder = createEncoder(readFile("big.txt"))
  var readStrm = newFileStream("big.txt", fmRead)
  var writeStrm = newFileStream("big.enc.txt", fmWrite)
  var buffer = "" 
  for x in encoder.encodeStream(readStrm):
    buffer.add(&"{x:b}")
    if buffer.len > 8:
      writeStrm.write(fromBin[int8](buffer[0..7]))
      buffer.delete(0, 7)

  if buffer.len > 0:
    writeStrm.write(fromBin[int8](buffer[0..^1]))

  writeStrm.flush()
#  writeStrm.setPosition(0)
#  var res: seq[char] = @[]
#  for y in encoder.decodeStream(writeStrm):
#    res.add(y)
#  
#  echo res.join("")
 
