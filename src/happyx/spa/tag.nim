## # Tag ✨
## 
## Provides a Tag type that represents an HTML tag.
## The file includes several functions for initializing new HTML tags,
## adding child tags to existing tags, and
## getting the level of nesting for a tag within its parent tags.
## The file also includes a function for converting a tag and
## its child tags to a string representation with proper indentation and attributes.
## 
## ## Usage 🔨
## 
## .. code-block:: nim
##    var html = initTag(
##      "div",
##      @[
##        textTag("Hello, world!"),
##        textTag("This is text tag"),
##      ]
##    )
## 
## It's low-level usage. At high-level you'll write HTML with `buildHtml` macro:
## 
## .. code-block:: nim
##    var html = buildHtml:
##      tDiv:
##        "Hello, world!"
##        "This is text tag"
## 
import
  strutils,
  strformat,
  strtabs,
  htmlparser,
  xmltree,
  regex


when defined(js):
  import dom


type
  TagRef* = ref Tag
  Tag* = object
    name*: string
    parent*: TagRef
    attrs*: StringTableRef
    args*: seq[string]
    children*: seq[TagRef]
    isText*: bool  ## Ignore attributes and children when true
    onlyChildren*: bool  ## Ignore self and shows only children


const
  UnclosedTags* = [
    "area", "base", "basefont", "br", "col", "frame", "hr",
    "img", "isindex", "link", "meta", "param", "wbr", "source",
    "input"
  ]
  NimKeywords* = [
    "if", "elif", "else", "using", "type", "of", "in", "notin", "and",
    "binding", "mixin", "type", "div", "mod", "case", "while", "for",
    "method", "proc", "func", "iterator", "template", "converter", "macro",
    "typed", "untyped", "int", "int8", "int16", "int32", "int64", "int128",
    "float", "float32", "float64", "string", "cstring", "when", "defined",
    "declared", "import", "from", "try", "except", "finally", "as", "var",
    "let", "const"
  ]



func initTag*(name: string, attrs: StringTableRef,
              children: seq[TagRef] = @[],
              onlyChildren: bool = false): TagRef =
  ## Initializes a new HTML tag with the given name, attributes, and children.
  ## 
  ## Args:
  ## - `name`: The name of the HTML tag to create.
  ## - `attrs`: The attributes to set for the HTML tag.
  ## - `children`: The children to add to the HTML tag.
  ## 
  ## Returns:
  ## - A reference to the newly created HTML tag.
  result = TagRef(
    name: name, isText: false, parent: nil,
    attrs: attrs, children: @[], args: @[],
    onlyChildren: onlyChildren
  )
  for child in children:
    if child.isNil():
      continue
    child.parent = result
    result.children.add(child)


func initTag*(name: string, children: seq[TagRef] = @[],
              onlyChildren: bool = false): TagRef =
  ## Initializes a new HTML tag without attributes but with children
  ## 
  ## Args:
  ## - `name`: tag name
  ## - `children`: The children to add to the HTML tag.
  ## 
  ## Returns:
  ## - A reference to the newly created HTML tag.
  result = TagRef(
    name: name, isText: false, parent: nil,
    attrs: newStringTable(), children: @[], args: @[],
    onlyChildren: onlyChildren
  )
  for child in children:
    if child.isNil():
      continue
    child.parent = result
    result.children.add(child)


func initTag*(name: string, isText: bool, attrs: StringTableRef,
              children: seq[TagRef] = @[],
              onlyChildren: bool = false): TagRef =
  ## Initializes a new HTML tag with the given name, whether it's text or not, attributes, and children.
  ## 
  ## Args:
  ## - `name`: The name of the HTML tag to create.
  ## - `isText`: Whether the tag represents text.
  ## - `attrs`: The attributes to set for the HTML tag.
  ## - `children`: The children to add to the HTML tag.
  ## 
  ## Returns:
  ## - A reference to the newly created HTML tag.
  result = TagRef(
    name: name, isText: isText, parent: nil,
    attrs: attrs, children: @[], args: @[],
    onlyChildren: onlyChildren
  )
  for child in children:
    if child.isNil():
      continue
    child.parent = result
    result.children.add(child)


func initTag*(name: string, isText: bool, children: seq[TagRef] = @[],
              onlyChildren: bool = false): TagRef =
  ## Initializes a new HTML tag
  result = TagRef(
    name: name, isText: isText, parent: nil,
    attrs: newStringTable(), children: @[], args: @[],
    onlyChildren: onlyChildren
  )
  for child in children:
    if child.isNil():
      continue
    child.parent = result
    result.children.add(child)


func tag*(name: string): TagRef {.inline.} =
  ## Shortcut for `initTag func<#initTag,string,seq[TagRef]>`_
  runnableExamples:
    var root = tag"div"
  TagRef(
    name: name, isText: false, parent: nil,
    attrs: newStringTable(), children: @[], args: @[],
    onlyChildren: false
  )


func tag*(tag: TagRef): TagRef {.inline.} =
  TagRef(
    name: tag.name, isText: tag.isText, parent: tag.parent,
    attrs: tag.attrs, children: tag.children,
    onlyChildren: tag.onlyChildren, args: @[],
  )


func textTag*(text: string): TagRef {.inline.} =
  ## Shortcur for `initTag func<#initTag,string,bool,seq[TagRef],bool>`_
  runnableExamples:
    var root = textTag"Hello, world!"
  TagRef(
    name: "", isText: true, parent: nil,
    attrs: newStringTable(), children: @[], args: @[],
    onlyChildren: false
  )


func add*(self: TagRef, tags: varargs[TagRef]) =
  ## Adds `other` tag into `self` tag
  runnableExamples:
    var
      rootTag = tag"div"
      child1 = tag"p"
      child2 = tag"p"
    rootTag.add(child1, child2)
  for tag in tags:
    if tag.isNil():
      continue
    self.children.add(tag)
    tag.parent = self


proc xml2Tag(xml: XmlNode): TagRef =
  case xml.kind
  of xnElement:
    if xml.attrsLen > 0:
      result = initTag(xml.tag)
      for key, value in xml.attrs:
        if value == "":
          result.args.add(key)
        else:
          result.attrs[key] = value
    else:
      result = initTag(xml.tag)
  of xnText:
    if re"\A\s+\z" notin xml.text:
      result = initTag(xml.text.replace(re" +\z", ""), true)
  else:
    discard


proc xmlTree2Tag(current, parent: TagRef, tree: XmlNode) =
  let tag = tree.xml2Tag()
  if not tag.isNil():
    current.add(tag)
  if tree.kind == xnElement:
    for child in tree.items:
      tag.xmlTree2Tag(current, child)


proc tagFromString*(source: string): TagRef {.inline.} =
  ## Translates raw HTML string into TagRef
  let xmlNode = parseHtml(source)
  result = initTag("div", @[], true)
  result.xmlTree2Tag(nil, xmlNode)
  result = result.children[0].children[0]


func addArg*(self: TagRef, arg: string) =
  self.args.add(arg)


func addArgIter*(self: TagRef, arg: string) =
  ## Adds argument into current tag and all children
  if self.args.len == 0:
    self.args.add(arg)
  for i in self.children:
    i.addArgIter(arg)


when defined(js):
  proc toDom*(self: TagRef): tuple[n: Node, b: bool] =
    ## converts tag into DOM Element
    if self.isText:
      # detect text node
      return (n: document.createTextNode(self.name), b: false)
    elif self.onlyChildren:
      # detect all children
      var res = document.createElement("div")
      # iter over all children
      for child in self.children:
        let dom = child.toDom()
        if dom.b:
          while dom.n.len > 0:
            res.appendChild(dom.n.childNodes[0])
        else:
          res.appendChild(dom.n)
      return (n: res, b: true)
    # normal tag
    var res = document.createElement(self.name)
    # attributes
    for key in self.attrs.keys():
      res.setAttribute(key, self.attrs[key])
    # args
    for arg in self.args:
      res.setAttribute(arg, "")
    # children
    for child in self.children:
      let dom = child.toDom()
      # only children
      if dom.b:
        while dom.n.len > 0:
          res.appendChild(dom.n.childNodes[0])
      else:
        res.appendChild(dom.n)
    return (n: res, b: false)


func lvl*(self: TagRef): int =
  ## This function returns the level of nesting of the current tag within its parent tags.
  runnableExamples:
    var
      root = tag"div"
      child1 = tag"h1"
      child2 = tag"h2"
    root.add(child1)
    child1.add(child2)
    assert child2.lvl == 2
    assert child1.lvl == 1
    assert root.lvl == 0
  result = 0
  var tag = self
  while not isNil(tag.parent):
    tag = tag.parent
    if not tag.onlyChildren:
      inc result


{. push inline .}

func `[]`*(self: TagRef, attrName: string): string =
  ## Returns attribute by name
  self.attrs[attrName]


func `[]=`*(self: TagRef, attrName: string, attrValue: string) =
  ## Sets a new value for attribute or create new attribute
  self.attrs[attrName] = attrValue


func getAttribute*(self: TagRef, attrName: string, default: string = ""): string =
  ## Returns attribute value if exists or default value if not.
  if attrName in self.attrs:
    self.attrs[attrName]
  else:
    default

{. pop .}


func findByTag*(self: TagRef, tag: string): seq[TagRef] =
  ## Finds all tags by name
  result = @[]
  for child in self.children:
    if child.isText:
      continue
    for i in child.findByTag(tag):
      result.add(i)
    if child.name == tag:
      result.add(child)


func get*(self: TagRef, tag: string): TagRef =
  ## Returns tag by name
  for child in self.children:
    if tag == child.name:
      return child
  raise newException(ValueError, fmt"<{self.name}> at level [{self.lvl}] doesn't have tag <{tag}>")


func `$`*(self: TagRef): string =
  ## This function returns a string representation of the current tag and its child tags, if any.
  ## The function formats the tag with proper indentation based on the level of nesting
  ## and includes any attributes specified for the tag.
  ## If the tag is a text tag, the function simply returns the tag's name.
  let
    level = "  ".repeat(self.lvl)
    argsStr = self.args.join(" ")

  if self.isText:
    return self.name
  
  var attrs = ""
  for key, value in self.attrs.pairs():
    attrs &= " " & key & "=" & "\"" & value & "\""

  if self.onlyChildren:
    let children = self.children.join("\n")
    return fmt"{level}{children}{level}"

  if self.children.len > 0:
    let children = "\n" & self.children.join("\n") & "\n"
    fmt"{level}<{self.name}{attrs} {argsStr}>{children}{level}</{self.name}>"
  elif self.name in UnclosedTags:
    fmt"{level}<{self.name}{attrs} {argsStr}>"
  else:
    fmt"{level}<{self.name}{attrs} {argsStr}></{self.name}>"
