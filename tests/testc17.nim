import ../src/happyx


serve "127.0.0.1", 5000:
  [get, post] "/":
    return "This will be respond only on GET or POST"
  
  "/anyMethod":
    discard
