## # Form Data 👨‍🔬
## 
## Provides working with `XML`, `form-data` and `x-www-form-urlencoded`.
## 
## This module used by request models so you can use it at high-level
## 
## .. code-block::nim
##    model MyModel:
##      img: FormDataItem
##      context: string
##    
##    serve "127.0.0.1", 5000:
##      post "/upload/[data:MyModel:formData]":
##        # Working with form-data
##        echo data.img.filename
##        return {"response": {
##          "filename": data.img.filename,
##          "content-type": data.img.contentType
##        }}
## 

import
  # Stdlib
  std/tables,
  std/strtabs,
  std/strutils,
  std/uri,
  std/xmltree,
  std/xmlparser,
  std/json,
  # Thirdparty
  regex


type FormDataItem* = object
  data*, filename*, contentType*, name*: string


proc parseFormData*(formData: string): (StringTableRef, TableRef[string, FormDataItem]) =
  ## Parses `form-data` into `StringTableRef`
  result = (newStringTable(), newTable[string, FormDataItem]())
  let
    formDataSeparator = re2"\-{2,}\w+(\-{2})?\r\n"
    lineSeparator = "\r\n"
    data = formData.split(formDataSeparator)
  for item in data:
    let lines = item.split(lineSeparator)
    var
      key = ""
      data = ""
      filename = ""
      contentType = ""
      i = 0
    for line in lines:
      if line == "": continue
      if line.startsWith("Content-Disposition"):
        # every param
        for param in line.split(re2"\s*;\s*"):
          let lparam = param.toLower()
          if lparam.startsWith("name"):
            key = param.split("\"")[1]
          elif lparam.startsWith("filename"):
            filename = param.split("\"")[1]
      elif line.startsWith("Content-Type"):
        contentType = line.split(re2":\s*")[1]
      else:
        data &= line
        if i < lines.len:
          data &= "\r\n"
      inc i
    if key.len > 0 and data.len > 0:
      let d =
        if filename.len == 0:
          data.replace(re2"\A\s+", "").replace(re2"\s+\z", "")
        else:
          data
      result[0][key] = d
      result[1][key] = FormDataItem(data: d, name: key, filename: filename, contentType: contentType)


proc iterateOverXml(tree: XmlNode, jsonNode: var JsonNode, path: var seq[string], parent: XmlNode = nil) =
  for child in tree.items:
    if child.kind == xnElement:
      # Working with all children
      path.add(child.tag)
      iterateOverXml(child, jsonNode, path, tree)
      discard path.pop()
    elif child.kind == xnText:
      # Working with text
      var
        current = jsonNode
        i = 0
      for p in path:
        if current.kind == JObject:
          if not current.hasKey(p) and i < path.len-1:
            # If current hasn't key `p` and i < path last elem idx
            current[p] = newJObject()
          elif not current.hasKey(p):
            # current hasn't key p
            let
              nodeType =
                if not tree.isNil() and not tree.attrs.isNil() and tree.attrs.hasKey("type"):
                  tree.attrs["type"]
                else:
                  "string"
              text = child.text.replace(re2"\A\s+", "").replace(re2"\s+\z", "")
            # Parse type
            current[p] =
              case nodeType.toLower()
              of "int":
                newJInt(parseInt(text))
              of "float":
                newJFloat(parseFloat(text))
              of "bool", "boolean":
                newJBool(parseBool(text))
              else:
                newJString(child.text)
          current = current[p]
        inc i


proc parseXmlBody*(data: string): JsonNode =
  let xml = parseXml(data)
  var
    res = newJObject()
    path: seq[string] = @[]
  iterateOverXml(xml, res, path)
  res


proc parseXWwwFormUrlencoded*(data: string): StringTableRef =
  ## Parses `x-www-form-urlencoded` into `StringTableRef`.
  result = newStringTable()
  let
    decoded = decodeUrl(data)
    splitted = decoded.split("&")
  for param in splitted:
    let data = param.split("=")
    if data.len == 2:
      result[data[0]] = data[1]
