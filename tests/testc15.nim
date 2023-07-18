import
  ../src/happyx


model MyModel:
  x: int = 100


type
  Language = enum
    lNim = "nim",
    lPython = "python",
    lJavaScript = "javascript"


serve "127.0.0.1", 5000:
  post "/[m:MyModel:urlencoded]":
    echo req.body
    echo m.x
  
  get "/language/$lang?:enum(Language)":
    # lang is lNim by default
    return fmt"Hello from {lang}"
