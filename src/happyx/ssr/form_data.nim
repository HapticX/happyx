## # Form Data 👨‍🔬
## 
## Provides working with `form-data` and `x-www-form-urlencoded`.
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
  tables,
  strtabs,
  strutils,
  mimetypes,
  uri,
  # Thirdparty
  regex


type FormDataItem* = object
  data*, filename*, contentType*, name*: string


proc parseFormData*(formData: string): (StringTableRef, TableRef[string, FormDataItem]) =
  ## Parses `form-data` into `StringTableRef`
  result = (newStringTable(), newTable[string, FormDataItem]())
  let
    formDataSeparator = re"\-{6}\w+(\-{2})?\r\n"
    lineSeparator = re"\r\n"  
    data = formData.split(formDataSeparator)
    m = newMimetypes()
  for item in data:
    let lines = item.split(lineSeparator)
    var
      key = ""
      data = ""
      filename = ""
      contentType = ""
      i = 0
    for line in lines:
      if line.startsWith("Content-Disposition"):
        # every param
        for param in line.split(re"\s*;\s*"):
          let lparam = param.toLower()
          if lparam.startsWith("name"):
            key = param.split("\"")[1]
          elif lparam.startsWith("filename"):
            filename = param.split("\"")[1]
      elif line.startsWith("Content-Type"):
        contentType = line.split(re":\s*")[1]
      else:
        data &= line
        if i < lines.len:
          data &= "\r\n"
      inc i
    if key.len > 0 and data.len > 0:
      let d =
        if filename.len == 0:
          data.replace(re"\A\s*([\s\S]+?)\s*\z", "$1")
        else:
          data
      result[0][key] = d
      result[1][key] = FormDataItem(data: d, name: key, filename: filename, contentType: contentType)


proc parseXWwwFormUrlencoded*(data: string): StringTableRef =
  ## Parses `x-www-form-urlencoded` into `StringTableRef`.
  result = newStringTable()
  let decoded = decodeUrl(data)
  for param in decoded.split("&"):
    let data = param.split("=")
    result[data[0]] = data[1]
