# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
import sequtils
import sugar
import algorithm
import bitops
import strformat
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

proc encode(list: Node, c: char, path: int, depth: uint): int =
  let leftNum = bitor(path shl 1, 1)
  if list.kind == Leaf:
    return path
  if c in list.left.chList:
    return encode(list.left, c, leftNum, depth + 1)
  elif c in list.right.chList:
    return encode(list.right, c, path shl 1, depth + 1)

proc decodePath(root: Node, list: Node, p: seq[char], r: var seq[char]) : seq[char]  =
  if p.len == 0:
    r.add(list.l.ch)
    return r
  let rest = p[1..^1]
  if list.kind == Leaf:
    r.add(list.l.ch)
    result = decodePath(root, root, p, r)
  elif p[0] == '1':
    result = decodePath(root, list.left, rest, r)
  else:
    result = decodePath(root, list.right, rest, r)

proc encodeChr(list: Node, c: char): int =
  return encode(list, c, 0, 0)


proc toLeaf(freq: seq[(char, int)]): seq[Node] =
  freq.map(s => Node(kind: Leaf, l: (weight: s[1], ch: s[0])))
  
proc createEncoder(chList: string): Node =
  let chList = toSeq(chList.items)
  var x = sorted(toLeaf(freq(chList)), myCmp)
  while not isSingle(x):
    x = combine(x)
  return x[0]

proc encodeStr(node: Node, str: string): seq[int] =
  let s = toSeq(str.items)
  return s.map(x => node.encodeChr(x))


when isMainModule:
  let encoder = createEncoder("aaaakkkggggli")
  encoder.print()
  echo "aaaakkkggggli"
  let encodedStr = join(encoder.encodeStr("aaaakkkggggli").map(x => &"{x:b}"), "")
  echo join(encoder.encodeStr("aaaakkkggggli").map(x => &"{x:b}"), "")
  var res: seq[char] = @[]
  echo toSeq("aaaakkkggggli").map(x => &"{int(x):b}").join("")
  echo(encoder.decodePath(encoder, toSeq(encodedStr), res).join(""))
