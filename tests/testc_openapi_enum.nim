## Regression for https://github.com/HapticX/happyx/issues/367
{.define: happyxSkipServeMain.}
import
  std/json,
  std/sequtils,
  std/unittest,
  ../src/happyx


type
  options_encoding* = enum
    encodingA, encodingB


model DataProcessRequest:
  data: string = ""
  storage: options_encoding = encodingA
  xtemplate: string = ""


serve "127.0.0.1", 5000:
  get "/":
    return %*{"response": "ok"}

  post "/api/process[r:DataProcessRequest:json]":
    return %*{"response": "success"}


suite "OpenAPI enum fields (#367)":
  test "schema includes enum property storage":
    let doc = openApiJson()
    let schema = doc["components"]["schemas"]["DataProcessRequest"]
    check schema["properties"].hasKey("storage")
  test "storage field is string enum":
    let doc = openApiJson()
    let storage = doc["components"]["schemas"]["DataProcessRequest"]["properties"]["storage"]
    check storage["type"].getStr == "string"
    check storage["enum"].kind == JArray
    check storage["enum"].getElems().mapIt(it.getStr).contains("encodingA")
    check storage["enum"].getElems().mapIt(it.getStr).contains("encodingB")
  test "post route documents JSON request body":
    let doc = openApiJson()
    let post = doc["paths"]["/api/process"]["post"]
    check post["requestBody"]["content"].hasKey("application/json")
