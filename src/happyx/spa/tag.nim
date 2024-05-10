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
  std/strutils,
  std/strformat,
  std/strtabs,
  std/sequtils,
  std/htmlparser,
  std/xmltree,
  regex


when defined(js):
  import std/dom

  type
    TagRef* = ref object of Element
      onlyChildren*: bool  ## Ignore self and shows only children
    VmTagRef* = ref object
      name*: string
      parent*: VmTagRef
      attrs*: StringTableRef
      args*: seq[string]
      children*: seq[VmTagRef]
      isText*: bool  ## Ignore attributes and children when true
      onlyChildren*: bool  ## Ignore self and shows only children
else:
  type
    TagRef* = ref object
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
    "input", "!DOCTYPE"
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


proc add*(self: TagRef, tags: varargs[TagRef]) =
  ## Adds `other` tag into `self` tag
  runnableExamples:
    var
      rootTag = tag"div"
      child1 = tag"p"
      child2 = tag"p"
    rootTag.add(child1, child2)
  when defined(js):
    for tag in tags:
      if tag.isNil():
        continue
      if tag.onlyChildren:
        for i in tag.childNodes[0..^1]:
          self.appendChild(i)
      else:
        self.appendChild(tag)
  else:
    for tag in tags:
      if tag.isNil():
        continue
      self.children.add(tag)
      tag.parent = self


when defined(js):
  proc setAttributes(name: string, e: TagRef, attrs: StringTableRef) =
    if name.toLower() in ["svg", "path", "circle", "rect"]:
      if attrs.hasKey("class"):
        let a = cstring(attrs["class"])
        {.emit: "`e`.setAttributeNS(null, 'class', `a`);".}
      for key, val in attrs.pairs:
        if key != "class":
          e.setAttribute(cstring(key), cstring(val))
    else:
      for key, val in attrs.pairs:
        e.setAttribute(cstring(key), cstring(val))

  proc newElement(name: string): TagRef =
    if name.toLower() in ["svg", "path", "circle", "rect"]:
      result = TagRef()
      let n = cstring(name)
      {.emit: "`result` = document.createElementNS('http://www.w3.org/2000/svg', `n`)".}
    else:
      result = document.createElement(cstring(name)).TagRef


proc initTag*(name: string, attrs: StringTableRef,
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
  when defined(js):
    result = newElement(name)
    result.onlyChildren = onlyChildren
    setAttributes(name, result, attrs)
    for child in children:
      if child.isNil:
        continue
      result.add(child)
  else:
    result = TagRef(
      name: name, isText: false, parent: nil,
      attrs: attrs, children: @[], args: @[],
      onlyChildren: onlyChildren
    )
    for child in children:
      result.add(child)


proc initTag*(name: string, children: seq[TagRef] = @[],
              onlyChildren: bool = false): TagRef =
  ## Initializes a new HTML tag without attributes but with children
  ## 
  ## Args:
  ## - `name`: tag name
  ## - `children`: The children to add to the HTML tag.
  ## 
  ## Returns:
  ## - A reference to the newly created HTML tag.
  when defined(js):
    result = newElement(name)
    result.onlyChildren = onlyChildren
    for child in children:
      if not child.isNil:
        result.add(child)
  else:
    result = TagRef(
      name: name, isText: false, parent: nil,
      attrs: newStringTable(), children: @[], args: @[],
      onlyChildren: onlyChildren
    )
    for child in children:
      result.add(child)


proc initTag*(name: string, isText: bool, attrs: StringTableRef,
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
  when defined(js):
    if isText:
      result = document.createTextNode(cstring(name)).TagRef
    else:
      result = newElement(name)
      result.onlyChildren = onlyChildren
      setAttributes(name, result, attrs)
      for child in children:
        if child.isNil:
          continue
        result.add(child)
  else:
    result = TagRef(
      name: name, isText: isText, parent: nil,
      attrs: attrs, children: @[], args: @[],
      onlyChildren: onlyChildren
    )
    for child in children:
      result.add(child)


proc initTag*(name: string, isText: bool, children: seq[TagRef] = @[],
              onlyChildren: bool = false): TagRef =
  ## Initializes a new HTML tag
  when defined(js):
    if isText:
      result = document.createTextNode(cstring(name)).TagRef
    else:
      result = newElement(name)
      result.onlyChildren = onlyChildren
      for child in children:
        if child.isNil:
          continue
        result.add(child)
  else:
    result = TagRef(
      name: name, isText: isText, parent: nil,
      attrs: newStringTable(), children: @[], args: @[],
      onlyChildren: onlyChildren
    )
    for child in children:
      result.add(child)


proc tag*(name: string): TagRef {.inline.} =
  ## Shortcut for `initTag func<#initTag,string,seq[TagRef]>`_
  runnableExamples:
    var root = tag"div"
  when defined(js):
    result = newElement(name)
    result.onlyChildren = false
  else:
    TagRef(
      name: name, isText: false, parent: nil,
      attrs: newStringTable(), children: @[], args: @[],
      onlyChildren: false
    )


proc tag*(tag: TagRef): TagRef {.inline.} =
  when defined(js):
    result = tag.Element.cloneNode(true).Element.TagRef
    result.onlyChildren = tag.onlyChildren
  else:
    result = TagRef(
      name: tag.name, isText: tag.isText, parent: tag.parent,
      attrs: newStringTable(), children: @[],
      onlyChildren: tag.onlyChildren, args: @[],
    )
    for child in tag.children:
      result.add(child)
    for k, v in tag.attrs.pairs:
      result.attrs[k] = v


proc textTag*(text: string): TagRef {.inline.} =
  ## Shortcur for `initTag func<#initTag,string,bool,seq[TagRef],bool>`_
  runnableExamples:
    var root = textTag"Hello, world!"
  when defined(js):
    result = document.createTextNode(cstring(text)).TagRef
    result.onlyChildren = false
  else:
    TagRef(
      name: text, isText: true, parent: nil,
      attrs: newStringTable(), children: @[], args: @[],
      onlyChildren: false
    )


when defined(js):
  proc isText*(tag: TagRef): bool =
    return tag.nodeType == NodeType.TextNode
  
  proc attrs*(tag: TagRef): seq[Node] =
    return tag.attributes
  
  proc args*(tag: TagRef): seq[string] =
    result = @[]
    for i in tag.attributes.low..tag.attributes.high:
      if $tag.attributes[i].nodeValue == "":
        result.add($tag.attributes[i].nodeName)
  
  iterator pairs*(attrs: seq[Node]): tuple[key, val: string] =
    for i in attrs.low..attrs.high:
      yield (key: $attrs[i].nodeName, val: $attrs[i].nodeValue)


proc xml2Tag(xml: XmlNode): TagRef =
  case xml.kind
  of xnElement:
    if xml.attrsLen > 0:
      result = initTag(xml.tag)
      for key, value in xml.attrs:
        when defined(js):
          result.setAttribute(cstring(key), cstring(value))
        else:
          if value == "":
            result.args.add(key)
          else:
            result.attrs[key] = value
    else:
      result = initTag(xml.tag)
  of xnText:
    if re2"\A\s+\z" notin xml.text:
      result = initTag(xml.text.replace(re2" +\z", ""), true)
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
  result = result.children[0].children[0].TagRef


proc addArg*(self: TagRef, arg: string) =
  ## Adds arg into tag
  ## 
  ## ## Example
  ## 
  ## .. code-block:: nim
  ##    var tag = initTag("div")
  ##    echo tag  # <div></div>
  ##    tag.addArg("data-1")
  ##    echo tag  # <div data-1></div>
  ## 
  when defined(js):
    self.setAttribute(cstring(arg), "")
  else:
    self.args.add(arg)


proc addArgIter*(self: TagRef, arg: string) =
  ## Adds argument into current tag and all children
  ## 
  ## See also `addArg function #addArg,TagRef,string`_
  when defined(js):
    self.setAttribute(cstring(arg), "")
  else:
    if self.args.len == 0:
      self.args.add(arg)
  for i in self.children:
    i.TagRef.addArgIter(arg)


proc toSeqIter*(self: TagRef): seq[TagRef] =
  if self.onlyChildren:
    result = @[]
  else:
    result = @[self]
  when defined(js):
    for child in self.childNodes:
      result = result.concat(child.TagRef.toSeqIter)
  else:
    for child in self.children:
      result = result.concat(child.TagRef.toSeqIter)
  return result


# when defined(js):
#   proc toDom*(self: TagRef): tuple[n: Node, b: bool] =
#     return (n: self.Node, b: false)
# elif defined(js):
#   proc toDom*(self: TagRef): tuple[n: Node, b: bool] =
#     ## converts tag into DOM Element
#     if self.isText:
#       # detect text node
#       return (n: document.createTextNode(self.name), b: false)
#     elif self.onlyChildren:
#       # detect all children
#       var res = document.createElement("div")
#       # iter over all children
#       for child in self.children:
#         let dom = child.toDom()
#         if dom.b:
#           while dom.n.len > 0:
#             res.appendChild(dom.n.childNodes[0])
#         else:
#           res.appendChild(dom.n)
#       return (n: res, b: true)
#     # normal tag
#     var res = document.createElement(self.name)
#     # attributes
#     for key in self.attrs.keys():
#       res.setAttribute(key, self.attrs[key])
#     # args
#     for arg in self.args:
#       res.setAttribute(arg, "")
#     # children
#     for child in self.children:
#       let dom = child.toDom()
#       # only children
#       if dom.b:
#         while dom.n.len > 0:
#           res.appendChild(dom.n.childNodes[0])
#       else:
#         res.appendChild(dom.n)
#     return (n: res, b: false)


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
  when defined(js):
    while not tag.parentElement.isNil:
      tag = tag.parentElement.TagRef
      if not tag.onlyChildren:
        inc result
  else:
    while not isNil(tag.parent):
      tag = tag.parent
      if not tag.onlyChildren:
        inc result


{. push inline .}

func `[]`*(self: TagRef, attrName: string): string =
  ## Returns attribute by name
  when defined(js):
    $self.getAttribute(cstring(attrName))
  else:
    self.attrs[attrName]

func `[]`*(self: TagRef, index: int): TagRef =
  ## Returns tag by index
  self.children[index].TagRef


func `[]=`*(self: TagRef, attrName: string, attrValue: string) =
  ## Sets a new value for attribute or create new attribute
  when defined(js):
    self.setAttribute(cstring(attrName), cstring(attrValue))
  else:
    self.attrs[attrName] = attrValue


func getAttribute*(self: TagRef, attrName: string, default: string = ""): string =
  ## Returns attribute value if exists or default value if not.
  when defined(js):
    if self.hasAttribute(cstring(attrName)):
      $self.getAttribute(cstring(attrName))
    else:
      default
  else:
    if attrName in self.attrs:
      self.attrs[attrName]
    else:
      default

{. pop .}


func findByTag*(self: TagRef, tag: string): seq[TagRef] =
  ## Finds all tags by name
  result = @[]
  for child in (when defined(js): self.childNodes else: self.children):
    when defined(js):
      if child.nodeType == NodeType.TextNode:
        continue
      for i in child.TagRef.findByTag(tag):
        result.add(i)
      if $child.nodeName == tag.toUpper():
        result.add(child.TagRef)
    else:
      if child.isText:
        continue
      for i in child.findByTag(tag):
        result.add(i)
      if child.name == tag:
        result.add(child)


func get*(self: TagRef, tag: string): TagRef =
  ## Returns tag by name
  when defined(js):
    for child in self.childNodes:
      if tag.toUpper() == $child.nodeName:
        return child.TagRef
    raise newException(ValueError, fmt"<{self.nodeName}> at level [{self.lvl}] doesn't have tag <{tag}>")
  else:
    for child in self.children:
      if tag == child.name:
        return child
    raise newException(ValueError, fmt"<{self.name}> at level [{self.lvl}] doesn't have tag <{tag}>")


func `$`*(self: TagRef): string =
  ## This function returns a string representation of the current tag and its child tags, if any.
  ## The function formats the tag with proper indentation based on the level of nesting
  ## and includes any attributes specified for the tag.
  ## If the tag is a text tag, the function simply returns the tag's name.
  when defined(js):
    return $self.outerHTML
  else:
    let
      level = "  ".repeat(self.lvl)
      argsStr = self.args.join(" ")

    if self.isText:
      return self.name
    
    var attrs = ""
    for key, value in self.attrs.pairs():
      if value.len > 0:
        attrs &= " " & key & "=" & "\"" & value & "\""
      else:
        attrs &= " " & key

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


when defined(js):
  proc `$`*(self: Node): string =
    $self.outerHTML

  func add*(self: VmTagRef, tags: varargs[VmTagRef]) =
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

  proc initTagVm*(name: string, attrs: StringTableRef,
                children: seq[VmTagRef] = @[],
                onlyChildren: bool = false): VmTagRef =
    ## Initializes a new HTML tag with the given name, attributes, and children.
    ## 
    ## Args:
    ## - `name`: The name of the HTML tag to create.
    ## - `attrs`: The attributes to set for the HTML tag.
    ## - `children`: The children to add to the HTML tag.
    ## 
    ## Returns:
    ## - A reference to the newly created HTML tag.
    result = VmTagRef(
      name: name, isText: false, parent: nil,
      attrs: attrs, children: @[], args: @[],
      onlyChildren: onlyChildren
    )
    for child in children:
      result.add(child)

  proc initTagVm*(name: string, children: seq[VmTagRef] = @[],
                onlyChildren: bool = false): VmTagRef =
    ## Initializes a new HTML tag without attributes but with children
    ## 
    ## Args:
    ## - `name`: tag name
    ## - `children`: The children to add to the HTML tag.
    ## 
    ## Returns:
    ## - A reference to the newly created HTML tag.
    result = VmTagRef(
      name: name, isText: false, parent: nil,
      attrs: newStringTable(), children: @[], args: @[],
      onlyChildren: onlyChildren
    )
    for child in children:
      result.add(child)


  proc initTagVm*(name: string, isText: bool, attrs: StringTableRef,
                children: seq[VmTagRef] = @[],
                onlyChildren: bool = false): VmTagRef =
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
    result = VmTagRef(
      name: name, isText: isText, parent: nil,
      attrs: attrs, children: @[], args: @[],
      onlyChildren: onlyChildren
    )
    for child in children:
      result.add(child)


  proc initTagVm*(name: string, isText: bool, children: seq[VmTagRef] = @[],
                onlyChildren: bool = false): VmTagRef =
    ## Initializes a new HTML tag
    result = VmTagRef(
      name: name, isText: isText, parent: nil,
      attrs: newStringTable(), children: @[], args: @[],
      onlyChildren: onlyChildren
    )
    for child in children:
      result.add(child)


  proc tagVm*(name: string): VmTagRef {.inline.} =
    ## Shortcut for `initTag func<#initTag,string,seq[TagRef]>`_
    runnableExamples:
      var root = tag"div"
    VmTagRef(
      name: name, isText: false, parent: nil,
      attrs: newStringTable(), children: @[], args: @[],
      onlyChildren: false
    )


  proc tagVm*(tag: VmTagRef): VmTagRef {.inline.} =
    result = VmTagRef(
      name: tag.name, isText: tag.isText, parent: tag.parent,
      attrs: newStringTable(), children: @[],
      onlyChildren: tag.onlyChildren, args: @[],
    )
    for child in tag.children:
      result.add(child)
    for k, v in tag.attrs.pairs:
      result.attrs[k] = v


  proc textTagVm*(text: string): VmTagRef {.inline.} =
    ## Shortcur for `initTag func<#initTag,string,bool,seq[TagRef],bool>`_
    runnableExamples:
      var root = textTag"Hello, world!"
    VmTagRef(
      name: text, isText: true, parent: nil,
      attrs: newStringTable(), children: @[], args: @[],
      onlyChildren: false
    )


  proc xml2TagVm(xml: XmlNode): VmTagRef =
    case xml.kind
    of xnElement:
      if xml.attrsLen > 0:
        result = initTagVm(xml.tag)
        for key, value in xml.attrs:
          if value == "":
            result.args.add(key)
          else:
            result.attrs[key] = value
      else:
        result = initTagVm(xml.tag)
    of xnText:
      if re2"\A\s+\z" notin xml.text:
        result = initTagVm(xml.text.replace(re2" +\z", ""), true)
    else:
      discard


  proc xmlTree2Tag(current, parent: VmTagRef, tree: XmlNode) =
    let tag = tree.xml2TagVm()
    if not tag.isNil():
      current.add(tag)
    if tree.kind == xnElement:
      for child in tree.items:
        tag.xmlTree2Tag(current, child)


  proc tagFromStringVm*(source: string): VmTagRef {.inline.} =
    ## Translates raw HTML string into TagRef
    let xmlNode = parseHtml(source)
    result = initTagVm("div", @[], true)
    result.xmlTree2Tag(nil, xmlNode)
    result = result.children[0].children[0].VmTagRef


  proc addArg*(self: VmTagRef, arg: string) =
    ## Adds arg into tag
    ## 
    ## ## Example
    ## 
    ## .. code-block:: nim
    ##    var tag = initTag("div")
    ##    echo tag  # <div></div>
    ##    tag.addArg("data-1")
    ##    echo tag  # <div data-1></div>
    ## 
    self.args.add(arg)


  proc addArgIter*(self: VmTagRef, arg: string) =
    ## Adds argument into current tag and all children
    ## 
    ## See also `addArg function #addArg,TagRef,string`_
    if self.args.len == 0:
      self.args.add(arg)
    for i in self.children:
      i.VmTagRef.addArgIter(arg)


  proc toSeqIter*(self: VmTagRef): seq[VmTagRef] =
    if self.onlyChildren:
      result = @[]
    else:
      result = @[self]
    for child in self.children:
      result = result.concat(child.VmTagRef.toSeqIter)
    return result


  func lvl*(self: VmTagRef): int =
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

  func `[]`*(self: VmTagRef, attrName: string): string =
    ## Returns attribute by name
    self.attrs[attrName]

  func `[]`*(self: VmTagRef, index: int): VmTagRef =
    ## Returns tag by index
    self.children[index].VmTagRef


  func `[]=`*(self: VmTagRef, attrName: string, attrValue: string) =
    ## Sets a new value for attribute or create new attribute
    self.attrs[attrName] = attrValue


  func getAttribute*(self: VmTagRef, attrName: string, default: string = ""): string =
    ## Returns attribute value if exists or default value if not.
    if attrName in self.attrs:
      self.attrs[attrName]
    else:
      default

  {. pop .}


  func findByTag*(self: VmTagRef, tag: string): seq[VmTagRef] =
    ## Finds all tags by name
    result = @[]
    for child in self.children:
      if child.isText:
        continue
      for i in child.findByTag(tag):
        result.add(i)
      if child.name == tag:
        result.add(child)


  func get*(self: VmTagRef, tag: string): VmTagRef =
    ## Returns tag by name
    for child in self.children:
      if tag == child.name:
        return child
    raise newException(ValueError, fmt"<{self.name}> at level [{self.lvl}] doesn't have tag <{tag}>")


  func `$`*(self: VmTagRef): string =
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
      if value.len > 0:
        attrs &= " " & key & "=" & "\"" & value & "\""
      else:
        attrs &= " " & key

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
