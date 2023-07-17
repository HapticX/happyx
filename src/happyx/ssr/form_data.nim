## # Form Data 👨‍🔬
## 
## Provides working with `form-data`.
## 

import
  tables,
  strtabs,
  strutils,
  uri


type
  FormDataItem* = object
    key*: string
    data*: string
    filename*: string
  FormData* = TableRef[string, FormDataItem]


proc parseFormData*(formData: string): FormData =
  result = FormData()


proc parseXWwwFormUrlencoded*(data: string): StringTableRef =
  result = newStringTable()
  let decoded = decodeUrl(data)
  for param in decoded.split("&"):
    let data = param.split("=")
    result[data[0]] = data[1]
