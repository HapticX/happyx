import ../src/happyx


translatable:
  "Hello, world!":
    # Default value for unknown lang is "Hello, world!"
    "ru" -> "Привет, мир!"
    "fr" -> "Bonjour, monde!"


serve("127.0.0.1", 5000):
  get "/":
    return translate("Hello, world!")
  
  get "/nonStatic":
    var x = "Hello, "
    return translate(x & "world!")
