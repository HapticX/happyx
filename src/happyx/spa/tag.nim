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
  std/htmlparser,
  std/xmltree,
  ../core/constants


when defined(js):
  import std/dom

  type
    TagRef* = ref object of Element
      onlyChildren*: bool  ## Ignore self and shows only children
      lazyFunc*: proc(): TagRef
      lazy*: bool
    VmTagRef* = ref object
      name*: string
      parent*: VmTagRef
      attrs*: StringTableRef
      args*: seq[string]
      children*: seq[VmTagRef]
      isText*: bool  ## Ignore attributes and children when true
      onlyChildren*: bool  ## Ignore self and shows only children
      lazyFunc*: proc(): TagRef
      lazy*: bool
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
      lazyFunc*: proc(): TagRef
      lazy*: bool


const
  UnclosedTags* = [
    "area", "base", "basefont", "br", "col", "frame", "hr",
    "img", "isindex", "link", "meta", "param", "wbr", "source",
    "input", "!DOCTYPE"
  ]
  SvgElements* = [
    "animate", "animateMotion", "animateTransform", "circle", "clipPath",
    "defs", "desc", "ellipse", "feBlend", "feColorMatrix", "feComponentTransfer",
    "feComposite", "feConvolveMatrix", "feDiffuseLighting", "feDisplacementMap",
    "feDistantLight", "feDropShadow", "feFlood", "feFuncA", "feFuncB", "feFuncG",
    "feFuncR", "feGaussianBlur", "feImage", "feMerge", "feMergeNode", "feMorphology",
    "feOffset", "fePointLight", "feSpecularLighting", "feSpotLight", "feTitle",
    "feTurbulence", "filter", "foreignObject", "g", "image", "line", "linearGradient",
    "marker", "mask", "metadata", "mpath", "path", "pattern", "polygon", "polyline",
    "radialGradient", "rect", "set", "stop", "svg", "switch", "symbol", "text", "textPath",
    "use", "view"
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


when defined(js):
  {.emit: """//js
  const _originAddEventListener = Node.prototype.addEventListener;
  const _originRemoveEventListener = Node.prototype.removeEventListener;
  const _originCloneNode = Node.prototype.cloneNode;

  Node.prototype.__getEventIndex = function(target, targetArgs) {
    if (!this._eventListeners) {
      this._eventListeners = [];
      return -1;
    }
    if (!targetArgs) return -1;
    return this._eventListeners.findIndex(args => {
      for (let i = 0; i < args.length; i++)
        if (targetArgs[i] !== args[i]) return false;
      return true;
    });
  };

  Node.prototype.getEventListeners = function() {
    if (!this._eventListeners)
      this._eventListeners = [];
    return this._eventListeners;
  }

  const cloneEvents = (source, element, deep) => {
    for (const args of source.getEventListeners())
      Node.prototype.addEventListener.apply(element, args)
    
    if (source.lazy && !element.lazy){
      element.lazy = source.lazy;
      element.lazyFunc = source.lazyFunc;
    }

    if (deep) {
      for (let i = 0; i < source.childNodes.length; i++) {
        const sourceNode = source.childNodes[i];
        const targetNode = element.childNodes[i];
        if (sourceNode instanceof Node && targetNode instanceof Node) {
          cloneEvents(sourceNode, targetNode, deep);
        }
      }
    }
  };

  Node.prototype.addEventListener = function() {
    if (!this._eventListeners)
      this._eventListeners = [];
    this._eventListeners.push(arguments);
    return _originAddEventListener.apply(this, arguments);
  };

  Node.prototype.removeEventListener = function() {
    if (!this._eventListeners)
      this._eventListeners = [];
    const eventIndex = this.__getEventIndex(arguments);
    if (eventIndex !== -1)
      this._eventListeners.splice(eventIndex, 1);
    return _originRemoveEventListener.apply(this, arguments);
  };

  Node.prototype.cleanEventListeners = function() {
    // this.replaceWith(_originCloneNode.apply(this, arguments));
    if (this._eventListeners) {
      for (let i = 0; i < this._eventListeners.length; i++) {
        // _originRemoveEventListener.apply(node, node._eventListeners[i]);
        const listener = this._eventListeners[i];
        _originRemoveEventListener.apply(this, listener);
        listener = [];
        // this._eventListeners[i][1] = undefined;
      }
      this._eventListeners = [];
    }
  }

  Node.prototype.cloneNode = function(deep) {
    if (!this._eventListeners)
      this._eventListeners = [];
    const clonedNode = _originCloneNode.apply(this, arguments);
    if (clonedNode instanceof Node)
      cloneEvents(this, clonedNode, deep);
    return clonedNode;
  };
  """.}


proc add*(self: TagRef, tags: varargs[TagRef]) {.exportc: "tgadd".} =
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
        for i in tag.childNodes:
          self.add(i.TagRef)
      else:
        self.appendChild(tag.cloneNode(true))
  else:
    for tag in tags:
      if tag.isNil():
        continue
      self.children.add(tag)
      tag.parent = self


when defined(js):
  proc setAttributes(name: string, e: TagRef, attrs: StringTableRef) {.exportc: "stattrs".} =
    if name.toLower() in SvgElements:
      if attrs.hasKey("class"):
        let a = cstring(attrs["class"])
        {.emit: "`e`.setAttributeNS(null, 'class', `a`);".}
      for key, val in attrs.pairs:
        if key != "class":
          if key in htmlNonBoolAttrs:
            e.setAttribute(cstring(key), cstring(val))
          elif val.toLowerAscii() == "true":
            e.setAttribute(cstring(key), "")
          elif val.toLowerAscii() == "false":
            discard
          else:
            e.setAttribute(cstring(key), cstring(val))
    else:
      for key, val in attrs.pairs:
        if key in htmlNonBoolAttrs:
          e.setAttribute(cstring(key), cstring(val))
        elif val.toLowerAscii() == "true":
          e.setAttribute(cstring(key), "")
        elif val.toLowerAscii() == "false":
          discard
        else:
          e.setAttribute(cstring(key), cstring(val))

  proc newElement(name: string): TagRef {.exportc: "nwelm".} =
    if name.toLower() in SvgElements:
      result = TagRef()
      let n = cstring(name)
      {.emit: "`result` = document.createElementNS('http://www.w3.org/2000/svg', `n`)".}
    else:
      result = document.createElement(cstring(name)).TagRef


proc initTag*(name: string, attrs: StringTableRef,
              children: seq[TagRef] = @[],
              onlyChildren: bool = false): TagRef {.exportc: "tg1".} =
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
              onlyChildren: bool = false): TagRef {.exportc: "tg2".} =
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
              onlyChildren: bool = false): TagRef {.exportc: "tg3".} =
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
              onlyChildren: bool = false): TagRef {.exportc: "tg4".} =
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


proc lazyTag*(lazy: proc(): TagRef): TagRef =
  ## Initializes a new lazy HTML tag
  when defined(js):
    result = document.createComment("").TagRef
    result.onlyChildren = false
    result.lazy = true
    result.lazyFunc = lazy
  else:
    result = TagRef(
      name: "div", isText: false, parent: nil,
      attrs: newStringTable(), children: @[], args: @[],
      onlyChildren: false, lazyFunc: lazy, lazy: true
    )


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


proc xml2Tag*(xml: XmlNode): TagRef =
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
    result = initTag(xml.text, true)
  else:
    discard


proc xmlTree2Tag*(current, parent: TagRef, tree: XmlNode) =
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
  when defined(js):
    result = result.children[0].children[0].TagRef
  else:
    result = result.children[0].children[0]
  

proc findTagsAtTop*(tree: XmlNode, tag: string): seq[XmlNode] =
  result = @[]
  for i in tree:
    if i.kind == xnElement and i.tag == tag:
      result.add(i)
  return result


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
    for i in self.children:
      i.TagRef.addArgIter(arg)
  else:
    if self.args.len == 0:
      self.args.add(arg)
    for i in self.children:
      i.addArgIter(arg)


proc toSeqIter*(self: TagRef): seq[TagRef] =
  if self.onlyChildren:
    result = @[]
  else:
    result = @[self]
  when defined(js):
    for child in self.childNodes:
      for i in child.TagRef.toSeqIter:
        result.add(i)
  else:
    for child in self.children:
      for i in child.toSeqIter:
        result.add(i)
  return result


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
      when defined(js):
        tag = tag.parentElement.TagRef
      else:
        tag = tag.parentElement
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
  when defined(js):
    self.children[index].TagRef
  else:
    self.children[index]


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
    $self.outerHTML
  else:
    let
      level = "  ".repeat(self.lvl)
      argsStr = self.args.join(" ")

    if self.isText:
      if self.parent.name.toLower() == "script":
        return self.name
      else:
        return xmltree.escape(self.name)
    
    var attrs = ""
    for key, value in self.attrs.pairs():
      if value.len > 0:
        attrs &= " " & key & "=" & "\"" & value.replace("\"", "&quot;") & "\""
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


func ugly*(self: TagRef): string =
  when defined(js):
    return $self.outerHTML
  else:
    let argsStr = self.args.join(" ")
    if self.isText:
      return self.name
      
    var attrs = ""
    for key, value in self.attrs.pairs():
      if value.len > 0:
        attrs &= " " & key & "=" & "\"" & value & "\""
      else:
        attrs &= " " & key

    if self.onlyChildren:
      var children = ""
      for i in self.children:
        children &= i.ugly()
      return children

    if self.children.len > 0:
      var children = ""
      for i in self.children:
        children &= i.ugly()
      if argsStr.len == 0:
        fmt"<{self.name}{attrs}>{children}</{self.name}>"
      else:
        fmt"<{self.name}{attrs} {argsStr}>{children}</{self.name}>"
    elif self.name in UnclosedTags:
      if argsStr.len == 0:
        fmt"<{self.name}{attrs}>"
      else:
        fmt"<{self.name}{attrs} {argsStr}>"
    else:
      if argsStr.len == 0:
        fmt"<{self.name}{attrs}></{self.name}>"
      else:
        fmt"<{self.name}{attrs} {argsStr}></{self.name}>"


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


  proc xml2TagVm*(xml: XmlNode): VmTagRef =
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
      result = initTagVm(xml.text, true)
    else:
      discard


  proc xmlTree2Tag*(current, parent: VmTagRef, tree: XmlNode) =
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
    result = result.children[0].children[0]


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
      i.addArgIter(arg)


  proc toSeqIter*(self: VmTagRef): seq[VmTagRef] =
    if self.onlyChildren:
      result = @[]
    else:
      result = @[self]
    for child in self.children:
      for i in child.toSeqIter:
        result.add(i)
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
    self.children[index]


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
      if self.parent.name.toLower() == "script":
        return self.name
      else:
        return xmltree.escape(self.name)
    
    var attrs = ""
    for key, value in self.attrs.pairs():
      if value.len > 0:
        attrs &= " " & key & "=" & "\"" & value.replace("\"", "&quot;") & "\""
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
