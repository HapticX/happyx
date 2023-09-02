import ../src/happyx


type
  MyUniqueIdentifier* = object
    id: int

proc initMyUniqueIdentifier(matchedString: string): MyUniqueIdentifier =
  try:
    return MyUniqueIdentifier(id: parseInt(matchedString))
  except ValueError:
    # When matched wrong data
    return MyUniqueIdentifier(id: 0)

registerRouteParamType("my_unique_id", r"\d+", initMyUniqueIdentifier)


serve "127.0.0.1", 5000:
  [get, post] "/":
    return "This will be respond only on GET or POST"
  
  "/registered/{id:my_unique_id}":
    echo id.id
  
  "/anyMethod":
    discard
