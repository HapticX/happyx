import
  ../src/happyx,
  macros


regCORS:
  credentials: true
  origins: "https://www.google.com"  # You can send request from this address
  methods: ["GET", "POST", "PUT"]
  headers: "*"


decorator HelloWorld:
  # In this scope:
  # httpMethods: seq[string]
  # routePath: string
  # statementList: NimNode
  # arguments: seq[NimNode]
  statementList.insert(0,
    newCall("echo", )
  )
  for i in arguments:
    statementList[0].add(i)
    statementList[0].add(newLit", ")
  if statementList[0].len > 1:
    statementList[0].del(statementList[0].len-1)


serve("127.0.0.1", 5000):
  "/":
    return "Hello, world!"
  
  @HelloWorld(1, 2, 3, req)
  "/test-deco":
    return "Hello, world!"

  @AuthBasic  # username and password will in your code.
  get "/user/{id}":
    echo username
    echo password
    return {"response": {
      "id": id,
      "username": username,
      "password": password
    }}
