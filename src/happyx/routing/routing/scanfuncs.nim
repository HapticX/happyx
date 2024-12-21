import
  std/unicode,
  std/strutils,
  ../../private/scanutils,
  ../../core/constants


proc boolean*(input: string, boolVal: var bool, start: int, opt: bool = false): int =
  let inp = input[start..^1]
  if inp.startsWith("off"):
    boolVal = false
    return 3
  elif inp.startsWith("false"):
    boolVal = false
    return 5
  elif inp.startsWith("no"):
    boolVal = false
    return 2
  elif inp.startsWith("on"):
    boolVal = true
    return 2
  elif inp.startsWith("true"):
    boolVal = true
    return 4
  elif inp.startsWith("yes"):
    boolVal = true
    return 3
  if opt:
    return 0
  return -1


proc word*(input: string, strVal: var string, start: int, opt: bool = false): int =
  result = 0
  if input.len <= start or not input.runeAt(start).isAlpha:
    if opt:
      return 0
    return -1
  var res = ""
  for s in input[start..^1].runes:
    if s.isAlpha:
      res &= $s
      inc result
    else:
      break
  strVal = res


proc str*(input: string, strVal: var string, start: int, opt: bool = false): int =
  result = 0
  if input.len <= start or input[start] == '/':
    if opt:
      return 0
    return -1
  var res = ""
  for c in input[start..^1]:
    if c != '/':
      res &= c
      inc result
    else:
      break
  strVal = res


proc enumerate*[T: enum](input: string, e: var T, start: int, opt: bool = false): int =
  let inp = input[start..^1]
  for i in T:
    if inp.startsWith(i.symbolName):
      e = i
      return i.symbolName.len
    elif inp.startsWith($i):
      e = i
      return len($i)
  if opt:
    return 0
  return -1


proc integer*(input: string, intVal: var int, start: int, opt: bool = false): int =
  result = 0
  if input.len <= start or not input[start].isDigit:
    if opt:
      return 0
    return -1
  var res = ""
  for c in input[start..^1]:
    if c.isDigit:
      res &= c
      inc result
    else:
      break
  intVal = res.parseInt


proc realnum*(input: string, floatVal: var float, start: int, opt: bool = false): int =
  result = 0
  if input.len <= start or not input[start].isDigit:
    if opt:
      return 0
    return -1
  var res = ""
  for c in input[start..^1]:
    if c.isDigit or c == '.':
      res &= c
      inc result
    else:
      break
  floatVal = res.parseFloat


proc default*(input: string, strVal: var string, start: int): int =
  result = 0
  var i = 0
  while start+i < input.len:
    if input[start+i] == '}':
      break
    strVal &= input[start+i]
    inc result
    inc i


proc kind*(input: string, strVal: var string, start: int): int =
  result = 0
  let inp = input[start..^1]
  if inp.startsWith("int"):
    strVal = "int"
    inc result, 3
  elif inp.startsWith("bool"):
    strVal = "bool"
    inc result, 4
  elif inp.startsWith("path"):
    strVal = "path"
    inc result, 4
  elif inp.startsWith("word"):
    strVal = "word"
    inc result, 4
  elif inp.startsWith("float"):
    strVal = "float"
    inc result, 5
  elif inp.startsWith("string"):
    strVal = "string"
    inc result, 6
  elif inp.startsWith("enum"):
    strVal = "enum::"
    var opened = false
    for i in inp[4..^1]:
      if i == '(':
        inc result
        opened = true
      elif i == ')':
        inc result
        break
      elif opened:
        strVal &= i
        inc result
    inc result, 4


proc path*(input: string, strVal: var string, start: int): int =
  strVal = input[start..^1]
  strVal.len


func kind2scanable*(kind: string, opt: bool): string =
  when not exportPython and not exportJvm and not defined(napibuild):
    if opt:
      case kind
      of "string":
        "${str(true)}"
      of "int":
        "${integer(true)}"
      of "float":
        "${realnum(true)}"
      of "bool":
        "${boolean(true)}"
      of "word":
        "${word(true)}"
      of "path":
        "${path}"
      else:
        if kind.startsWith("enum"):
          "${enumerate}"
        else:
          ""
    else:
      case kind
      of "string":
        "${str}"
      of "int":
        "$i"
      of "float":
        "$f"
      of "bool":
        "${boolean}"
      of "word":
        "${word}"
      of "path":
        "${path}"
      else:
        if kind.startsWith("enum"):
          "${enumerate}"
        else:
          ""
  else:
    if opt:
      case kind
      of "string":
        "([^/]+)?"
      of "int":
        "(\\d+)?"
      of "float":
        "(\\d+\\.\\d+)?"
      of "bool":
        "(true|false|on|off|yes|no)?"
      of "word":
        "(\\w+)?"
      of "path":
        "([\\S]+)?"
      else:
        ""
    else:
      case kind
      of "string":
        "([^/]+)"
      of "int":
        "(\\d+)"
      of "float":
        "(\\d+\\.\\d+)"
      of "bool":
        "(true|false|on|off|yes|no)"
      of "word":
        "(\\w+)"
      of "path":
        "([\\S]+)"
      else:
        ""


func kind2tp*(kind: string): string =
  case kind
  of "string", "word", "path":
    "string"
  of "int":
    "int"
  of "float":
    "float"
  of "bool":
    "bool"
  else:
    if kind.startsWith("enum"):
      kind.split("::", 1)[1]
    else:
      ""


proc findParams*(route: string, purePath: var string): seq[tuple[name, kind: string, opt: bool, def: string]] =
  result = @[]
  var i = 0
  while i < route.len:
    let part = route[i..^1]
    var
      name: string
      kind: string = "string"
      def: string
    # {arg?:type=default}
    if part.scanf("{$w?:${kind}=${default}}", name, kind, def):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 5 + name.len + kind.len + def.len
    # $arg?:type=default
    elif part.scanf("$$$w?:${kind}=${default}", name, kind, def):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 4 + name.len + kind.len + def.len
    # {arg:type=default}
    elif part.scanf("{$w:${kind}=${default}}", name, kind, def):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 4 + name.len + kind.len + def.len
    # $arg:type=default
    elif part.scanf("$$$w:${kind}=${default}", name, kind, def):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 3 + name.len + kind.len + def.len
    # {arg=default}
    elif part.scanf("{$w=${default}}", name, def):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 3 + name.len + def.len
    # $arg=default
    elif part.scanf("$$$w=${default}", name, def):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 2 + name.len + def.len
    # {arg:type}
    elif part.scanf("{$w:${kind}}", name, kind):
      result.add((name: name, kind: kind, opt: false, def: def))
      purePath &= kind2scanable(kind, false)
      inc i, 3 + name.len + kind.len
    # $arg:type
    elif part.scanf("$$$w:${kind}", name, kind):
      result.add((name: name, kind: kind, opt: false, def: def))
      purePath &= kind2scanable(kind, false)
      inc i, 2 + name.len + kind.len
    # {arg?=default}
    elif part.scanf("{$w?=${default}}", name, def):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 4 + name.len + def.len
    # $arg?=default
    elif part.scanf("$$$w?=${default}", name, def):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 3 + name.len + def.len
    # {arg?:type}
    elif part.scanf("{$w?:${kind}}", name, kind):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 4 + name.len + kind.len
    # $arg?:type
    elif part.scanf("$$$w?:${kind}", name, kind):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 3 + name.len + kind.len
    # {arg?}
    elif part.scanf("{$w?}", name):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 3 + name.len
    # $arg?
    elif part.scanf("$$$w?", name):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 2 + name.len
    # {arg}
    elif part.scanf("{$w}", name):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 2 + name.len
    # $arg
    elif part.scanf("$$$w", name):
      result.add((name: name, kind: kind, opt: true, def: def))
      purePath &= kind2scanable(kind, true)
      inc i, 1 + name.len
    # [arg:ModelName]
    elif part.scanf("[$w:$w]", name, kind):
      inc i, 3 + name.len + kind.len
    # [arg:ModelName:json]
    elif part.scanf("[$w:$w:$w]", name, kind, def):
      inc i, 4 + name.len + kind.len + def.len
    else:
      purePath &= route[i]
      inc i


proc findModels*(route: string): seq[tuple[name, kind, mode: string]] =
  result = @[]
  var i = 0
  while i < route.len:
    let part = route[i..^1]
    var
      name: string
      kind: string
      mode: string = "JSON"
    # [arg:ModelName]
    if part.scanf("[$w:$w]", name, kind):
      result.add((name: name, kind: kind, mode: mode))
      inc i, 3 + name.len + kind.len
    # [arg:ModelName:json]
    elif part.scanf("[$w:$w:$w]", name, kind, mode):
      result.add((name: name, kind: kind, mode: mode))
      inc i, 4 + name.len + kind.len + mode.len
    else:
      inc i
