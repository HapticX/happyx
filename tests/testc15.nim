import
  ../src/happyx


type
  Language = enum
    lNim = "nim",
    lPython = "python",
    lJavaScript = "javascript"
  OptionsEncoding* = enum
      encodingA, encodingB

model TestModel:
  lang: Language

model MyModel:
  x: int = 100

model UploadImage:
  y: int
  # FormDataItem will parsed only on Form-Data mode
  img: FormDataItem


model DataProcessRequest: 
  data: string = ""
  storage: OptionsEncoding = encodingA
  xtemplate: string = "" 


mount Issue84:
  get "/":
    "Hello, world!"
  post "/":
    "Bye world"


serve "127.0.0.1", 5000:
  mount "/issue84" -> Issue84

  # on GET HTTP method at http://127.0.0.1:5000/
  get "/":
    {.gcsafe.}:
      return %*{
        "response": "success",
        "msg": "These are not the droids, you're looking for."
      }

  post "/api/process[r:DataProcessRequest:json]":
    {.gcsafe.}:
      # Return plain text

      # process data here

      return %*{
        "response": "success"
      }

  post "/urlencoded/[m:MyModel:urlencoded]":
    echo m.x
    return {"response": m.x}
  
  get "/teststatuscodes/{i:int}":
    ## you can test here status codes
    outHeaders["Server"] = "HappyX " & HpxVersion   ## Here just a server
    if i mod 2 == 0:
      outHeaders["Reason"] = "bye world"   ## 403: error reason
      statusCode = 403   ## i is not even
      return i
    return i
  
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
  
  post "/xml/[m:MyModel:xml]":
    ## Body:
    ## <MyModel>
    ##   <x type="int">10000</x>
    ## </MyModel>
    echo m.x
    return {"response": m.x}
  
  get "/language/$lang?:enum(Language)":
    ## lang is lNim by default
    return fmt"Hello from {lang}"
