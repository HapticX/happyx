## Provides working with HTML tags
import
  strutils,
  strformat,
  strtabs


type
  TagRef* = ref Tag
  Tag* = object
    name*: string
    parent*: TagRef
    attrs*: StringTableRef
    children*: seq[TagRef]
    isText*: bool


func initTag*(name: string, attrs: StringTableRef, children: varargs[TagRef]): TagRef =
  ## Initializes a new HTML tag
  result = TagRef(name: name, isText: false, parent: nil, attrs: attrs, children: @[])
  for child in children:
    child.parent = result
    result.children.add(child)


func initTag*(name: string, children: varargs[TagRef]): TagRef =
  ## Initializes a new HTML tag
  result = TagRef(name: name, isText: false, parent: nil, attrs: newStringTable(), children: @[])
  for child in children:
    child.parent = result
    result.children.add(child)


func initTag*(name: string, attrs: StringTableRef): TagRef =
  ## Initializes a new HTML tag
  TagRef(name: name, isText: false, parent: nil, attrs: attrs, children: @[])


func initTag*(name: string, isText: bool, attrs: StringTableRef, children: varargs[TagRef]): TagRef =
  ## Initializes a new HTML tag
  result = TagRef(name: name, isText: isText, parent: nil, attrs: attrs, children: @[])
  for child in children:
    child.parent = result
    result.children.add(child)


func initTag*(name: string, isText: bool, children: varargs[TagRef]): TagRef =
  ## Initializes a new HTML tag
  result = TagRef(name: name, isText: isText, parent: nil, attrs: newStringTable(), children: @[])
  for child in children:
    child.parent = result
    result.children.add(child)


func initTag*(name: string, isText: bool, attrs: StringTableRef): TagRef =
  ## Initializes a new HTML tag
  TagRef(name: name, isText: isText, parent: nil, attrs: attrs, children: @[])


func add*(self, other: TagRef) =
  ## Adds `other` tag into `self` tag
  self.children.add(other)


func lvl*(self: TagRef): int =
  result = 0
  var tag = self
  while not isNil(tag.parent):
    tag = tag.parent
    inc result


func `$`*(self: TagRef): string =
  ## Returns stringify HTML tag
  let level = "  ".repeat(self.lvl)

  if self.isText:
    return level & self.name
  
  let children = "\n" & self.children.join("\n") & "\n"
  var attrs = ""
  for key, value in self.attrs.pairs():
    attrs &= " " & key & "=" & "\"" & value & "\""
  fmt"{level}<{self.name}{attrs}>{children}{level}</{self.name}>"
