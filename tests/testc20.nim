import ../src/happyx


type Kind = enum
  str
  num

serve "127.0.0.1", 5000:
  get "/{k:enum(Kind)}/{x}":
    "1" & x
  get "/bool":
    "2"
  notfound:
    "3"