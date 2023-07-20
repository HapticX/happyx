import
  ../src/happyx


model MyModel:
  x: int = 100

model UploadImage:
  y: int
  # FormDataItem will parsed only on Form-Data mode
  img: FormDataItem


type
  Language = enum
    lNim = "nim",
    lPython = "python",
    lJavaScript = "javascript"


serve "127.0.0.1", 5000:
  post "/urlencoded/[m:MyModel:urlencoded]":
    echo m.x
    return {"response": m.x}
  
  post "/formData/[m:UploadImage:formdata]":
    # ⚠ In other request model modes field `img` will be not parsed
    echo m.img.name
    echo m.img.filename
    return {"response": {
      "filename": m.img.filename,
      "name": m.img.name,
      "content-type": m.img.contentType
    }}
  
  post "/json/[m:MyModel:json]":  # By default request models is JSON
    echo m.x
    return {"response": m.x}
  
  get "/language/$lang?:enum(Language)":
    # lang is lNim by default
    return fmt"Hello from {lang}"
