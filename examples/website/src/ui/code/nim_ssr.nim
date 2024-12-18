const
  ssrExample* = """import happyx

serve "127.0.0.1", 5000:
  get "/":
    return "Hello, world!"
"""
  fileResponseExample* = """import happyx

server "127.0.0.1", 5000:
  "/":
    return FileResponse("image.png")
"""
  pathParamsSsrExample* = """import happyx

server "127.0.0.1", 5000:
  "/user{id:int}":
    return fmt"Hello! user {id}"
"""
  nimSsrHelloWorldExample* = """import happyx

# Serve app at http://localhost:5000
serve "127.0.0.1", 5000:
  # GET Method
  get "/":
    # Respond plaintext
    return "Hello, world"
"""
  nimProjectSsr* = """project/
├─ src/
│  ├─ templates/
│  │  ├─ index.html
│  ├─ public/
│  │  ├─ icon.svg
│  ├─ main.nim
├─ README.md
├─ .gitignore
├─ happyx.cfg
├─ project.nimble
"""
  nimSsrCalc* = """serve "127.0.0.1", 5000:
  get "/calc/{left:float}/{op}/{right:float}":
    case op
    of "add": return fmt"{left + right}"
    of "sub": return fmt"{left - right}"
    of "del": return fmt"{left / right}"
    of "mul": return fmt"{left * right}"
    else:
      statusCode = 404
      return "failure"
"""
  nimPathParamsSsr* = """serve "127.0.0.1", 5000:
  get "/user/id{userId:int}":
    ## here we can use userId as immutable variable
    echo userId
    return $userId
"""
  nimAssignRouteParamsSsr* = """import happyx

# declare path params
pathParams:
  paramName int:  # assign param name
    optional  # param is optional
    mutable  # param is mutable variable
    default = 100  # default param value is 100


serve "127.0.0.1", 5000:
  # Use paramName
  get "/<paramName>":
    echo paramName
"""
  nimSsrTailwind* = """import happyx


serve "127.0.0.1", 5000:
  get "/":
    return buildHtml: tHtml:
      tHead:
        tTitle: "my joke page"
        # https://tailwindcss.com/docs/installation/play-cdn
        tScript(src = "https://cdn.tailwindcss.com")
      tBody:
        tH1(class = "text-3xl font-bold underline"):
          "Hello, world!"
"""
  nimSsrTailwindWithoutCdn* = """import happyx


serve "127.0.0.1", 5000:
  get "/":
    return buildHtml: tHtml:
      tHead:
        tTitle: "my joke page"
      tBody:
        tH1(class = "text-3xl font-bold underline"):
          "Hello, world!"
"""
  nimSsrAdvancedHelloWorld* = """import happyx


serve "127.0.0.1", 5000:
  get "/statusCode":
    statusCode = 404
    return "This page not working because I want it :p"
  
  get "/customHeaders":
    outHeaders["Backend-Server"] = "HappyX"
    return 0

  get "/customCookies":
    outCookies.add(setCookie("bestFramework", "HappyX!", secure = true, httpOnly = true))
    return 0
  
  get "/":
    statusCode = 401
    outHeaders["Reason"] = "Auth failed"
    outCookies.add(setCookie("happyx-auth-reason", "HappyX", secure = true, httpOnly = true))
    return 1
"""
  nimSsrAdditionalRoutes* = """import happyx


serve "127.0.0.1", 5000:
  setup:
    echo "this called once before server start."
    var x = 0

  middleware:
    echo req
    # you can use any variable from setup
    echo x
  
  notfound:
    return "Oops, seems like this route is not available"
  
  onException:
    echo e.msg
    echo e.name
    statusCode = 500
    return "Oops, seems like some error was raised"

  staticDir "/path/to/directory" -> "directory"
"""
  nimSsrRouteDecorator* = """import happyx

server "127.0.0.1", 5000:
  # This will add username and password
  @AuthBasic
  get "/user{id}":
    # Will return 401 if headers haven't "Authorization"
    return {"response": {
      "id": id,
      "username": username,  # from @AuthBasic
      "password": password  # from @AuthBasic
    }}
"""
  nimAssignRouteDecorator* = """import happyx
import macros


proc myCustomDecorator*(httpMethods: seq[string], path: string, statementList: NimNode, arguments: seq[NimNode]) = 
  # This decorator will add
  #   echo "Hello from {path}"
  # as leading statement in route at compile-time
  statementList.insert(0, newCall("echo", newLit("Hello from " & path)))


# Register our decorator
static:
  regDecorator("OurDecorator", myCustomDecorator)


# Another way to declare decorator
decorator HelloWorld:
  # In this scope:
  # httpMethods: seq[string]
  # routePath: string
  # statementList: NimNode
  # arguments: seq[NimNode]

  # Here we just add `echo` of all arguments
  statementList.insert(0, newCall("echo"))
  for i in arguments:
    statementList[0].add(i)
    statementList[0].add(newLit", ")
  if statementList[0].len > 1:
    statementList[0].del(statementList[0].len-1)


# Use it!
serve "127.0.0.1", 5000:
  @OurDecorator
  get "/":
    return 0

  @HelloWorld(1, 2, 3, req)
  get "/with-args":
    return 0
"""
  nimSsrMongoDb1* = """import
  happyx,  # import happyx web framework
  anonimongo,  # import anonimongo mongo db driver
  times


serve "127.0.0.1", 5000:
  setup:
    # Setup is main sync scope.
    # Here you can initialize all of you need.
    {.gcsafe.}:
      # Connect to mongodb
      var mongo = newMongo[AsyncSocket]()
      # check connection
      if not waitFor mongo.connect:
        quit "Cannot connect to localhost:27017"
      # declare users collection
      var usersColl = mongo["happyx_test"]["users"]
"""
  nimSsrMongoDb2* = """
  post "/user/new":
    ## Creates a new user
    {.gcsafe.}:
      let usersCount = await usersColl.count()
      let r = await usersColl.insert(@[
        bson({
          countId: usersCount,
          addedTime: now().toTime()
        })
      ])
      return %*{"response": if r.success: "success" else: "failure"}
"""
  nimSsrMongoDb3* = """
  get "/user/id{userId:int}":
    ## Get user by ID if exists
    {.gcsafe.}:
      let user = await usersColl.findOne(bson({
        countId: userId
      }))
      if user == nil:
        return %*{"response": "failure"}
      else:
        return %*{
          "countId": user["countId"].ofInt32,
          "addedTime": user["addedTime"].ofTime
        }
"""
  nimSsrMongoDb4* = """
  get "/users":
    ## Get all users
    {.gcsafe.}:
      var response = %*[]
      for i in await usersColl.findIter():
        response.add %*{
          "countId": i["countId"].ofInt32,
          "addedTime": i["addedTime"].ofTime
        }
      return response
"""
  nimSsrMongoDb* = """import
  happyx,  # import happyx web framework
  anonimongo,  # import anonimongo mongo db driver
  times


serve "127.0.0.1", 5000:
  setup:
    # Setup is main sync scope.
    # Here you can initialize all of you need.
    {.gcsafe.}:
      # Connect to mongodb
      var mongo = newMongo[AsyncSocket]()
      # check connection
      if not waitFor mongo.connect:
        quit "Cannot connect to localhost:27017"
      # declare users collection
      var usersColl = mongo["happyx_test"]["users"]
  
  post "/user/new":
    ## Creates a new user
    {.gcsafe.}:
      let usersCount = await usersColl.count()
      let r = await usersColl.insert(@[
        bson({
          countId: usersCount,
          addedTime: now().toTime()
        })
      ])
      return %*{"response": if r.success: "success" else: "failure"}
  
  get "/user/id{userId:int}":
    ## Get user by ID if exists
    {.gcsafe.}:
      let user = await usersColl.findOne(bson({
        countId: userId
      }))
      if user == nil:
        return %*{"response": "failure"}
      else:
        return %*{
          "countId": user["countId"].ofInt32,
          "addedTime": user["addedTime"].ofTime
        }
  
  get "/users":
    ## Get all users
    {.gcsafe.}:
      var response = %*[]
      for i in await usersColl.findIter():
        response.add %*{
          "countId": i["countId"].ofInt32,
          "addedTime": i["addedTime"].ofTime
        }
      return response
"""
  nimSsrNormSqlite* = """import
  happyx,  # import HappyX web framework
  norm/[model, sqlite],  # import Norm lib
  times


type User = ref object of Model
  lastLogin*: DateTime

proc newUser*(): User = User(lastLogin: now())


serve "127.0.0.1", 5000:
  setup:
    # Create database connection
    let dbConn = open("users.db", "", "", "")
    # Create table
    dbConn.createTables(newUser())
  
  post "/user/new":
    var user = newUser()
    try:
      dbConn.insert(user)
      return {"response": "success"}
    except DbError:
      return {"response": "failure"}
  
  get "/user/id{userId:int}":
    var user = newUser()
    try:
      dbConn.select(user, "id = ?", userId.int64)
      return {
        "id": user.id,
        "lastLogin": $user.lastLogin
      }
    except DbError:
      return {"response": "failure"}
        
  get "/users":
    var outUsers = @[newUser()]
    dbConn.selectAll(outUsers)

    var response = %*[]
    for i in outUsers:
      response.add %*{
        "id": i.id,
        "lastLogin": $i.lastLogin
      }
    return response
"""
  nimSsrNormSqlite1* = """import
  happyx,  # import HappyX web framework
  norm/[model, sqlite],  # import Norm lib
  times


type User = ref object of Model
  lastLogin*: DateTime

proc newUser*(): User = User(lastLogin: now())
"""
  nimSsrNormSqlite2* = """
serve "127.0.0.1", 5000:
  setup:
    # Create database connection
    let dbConn = open("users.db", "", "", "")
    # Create table
    dbConn.createTables(newUser())
"""
  nimSsrNormSqlite3* = """
  post "/user/new":
    var user = newUser()
    dbConn.insert(user)
    return {"response": "success"}
"""
  nimSsrNormSqlite4* = """
  get "/user/id{userId:int}":
    var user = newUser()
    try:
      dbConn.select(user, "id = ?", userId.int64)
      return {
        "id": user.id,
        "lastLogin": $user.lastLogin
      }
    except DbError:
      return {"response": "failure"}
     
"""
  nimSsrNormSqlite5* = """
  get "/users":
    var outUsers = @[newUser()]

    return %*outUsers
"""
  nimPostgreSql* = """import
  happyx,  # import HappyX web framework
  norm/[model, postgres],  # import Norm lib
  times


type User = ref object of Model
  lastLogin*: DateTime

proc newUser*(): User = User(lastLogin: now())


serve "127.0.0.1", 5000:
  setup:
    # Create database connection
    let dbConn = open("127.0.0.1", "postgres", "123456", "test")
    # Create table
    dbConn.createTables(newUser())
  
  post "/user/new":
    var user = newUser()
    try:
      dbConn.insert(user)
      return {"response": "success"}
    except DbError:
      return {"response": "failure"}
  
  get "/user/id{userId:int}":
    var user = newUser()
    try:
      dbConn.select(user, "id = ?", userId.int64)
      return {
        "id": user.id,
        "lastLogin": $user.lastLogin
      }
    except DbError:
      return {"response": "failure"}
        
  get "/users":
    var outUsers = @[newUser()]
    dbConn.selectAll(outUsers)

    var response = %*[]
    for i in outUsers:
      response.add %*{
        "id": i.id,
        "lastLogin": $i.lastLogin
      }
    return response
"""
  nimPostgreSql1* = """import
  happyx,  # import HappyX web framework
  norm/[model, postgres],  # import Norm lib
  times


type User = ref object of Model
  lastLogin*: DateTime

proc newUser*(): User = User(lastLogin: now())"""

  nimPostgreSql2* = """
serve "127.0.0.1", 5000:
  setup:
    # Create database connection
    let dbConn = open("127.0.0.1", "postgres", "123456", "test")
    # Create table
    dbConn.createTables(newUser())"""
  nimPostgreSql3* = """  post "/user/new":
    var user = newUser()
    try:
      dbConn.insert(user)
      return {"response": "success"}
    except DbError:
      return {"response": "failure"}"""
  nimPostgreSql4* = """  get "/user/id{userId:int}":
    var user = newUser()
    try:
      dbConn.select(user, "id = ?", userId.int64)
      return {
        "id": user.id,
        "lastLogin": $user.lastLogin
      }
    except DbError:
      return {"response": "failure"}"""
  nimPostgreSql5* = """  get "/users":
    var outUsers = @[newUser()]
    dbConn.selectAll(outUsers)

    var response = %*[]
    for i in outUsers:
      response.add %*{
        "id": i.id,
        "lastLogin": $i.lastLogin
      }
    return response"""
  nimSsrDocs1* = """import happyx

serve "127.0.0.1", 5000:
  get "/":
    ## Here we can describe this route
    ## It will be shown in swagger and redoc
    return "Hello, world!"
"""
  nimSsrDocs2* = """import happyx

serve "127.0.0.1", 5000:
  get "/":
    ## Here we can describe this route
    ## It will be shown in swagger and redoc
    ## 
    ## Responds **"Hello, world!"**
    return "Hello, world!"
"""
  nimSsrMounting* = """import happyx

mount Profile:
  "/":
    "Hello from /profile/"
  "/{id:int}":
    "Hello, user {id}! Route is /profile/{id}"
  "/settings":
    "Hello from /profile/settings"

serve "127.0.0.1", 5000:
  mount "/profile" -> Profile
"""
  nimSsrMountingSugar* = """import happyx

"/profile/id{id:int}" -> get:
  "Hello, user id{id}"

serve "127.0.0.1", 5000:
  discard
"""
  nimLiveViews1* = """import happyx

var counter = remember 0

liveview:
  "/":
    {counter}
    tButton:
      "click me!"
      @click:
        counter += 1

serve "127.0.0.1", 5000:
  discard
"""
  nimReactivityWatchers* = """import happyx

var counter = remember 0

counter.watch(old, new):
  echo "set counter to ", new, ", but before it be ", old

appRoutes "app":
  "/":
    {counter}
    tButton:
      "increase"
      @click:
        counter += 1
"""
  nimHiddenVariables* = """serve "127.0.0.1", 5000:
    get "/":
      # request
      echo req  # Request
      # URL path
      echo urlPath  # string
      # request method
      echo reqMethod  # HttpMethod
      # path queries
      echo query  # StringTableRef
      echo queryArr  # TableRef[string, seq[string]]
      # Request cookies
      echo inCookies  # StringTableRef
      # Request headers
      echo headers  # HttpHeaders

      # Response status code
      statusCode = 404
      # Response headers
      outHeaders = {
        "X-Created-At": 0
      }
      # Response cookies
      outCookies.add(setCookie("Hello", "world"))
"""
  nimSsrWebsockets* = """import happyx


type
  Msg* = object
    text: string
    fromId: int


serve "127.0.0.1", 5123:
  wsConnect:
    echo "Connected"
  
  ws "/listen":
    try:
      # wsData uses to fetch data from websocket connection
      let message = wsData.parseJson().to(Msg)

      # wsConnections is list of all active websocket connections
      for connection in wsConnections:
        if connection.readyState == Open:
          await connection.send $(%*{
            "text": message.text,
            "fromId": message.fromId
          })
    except JsonParsingError:
      # wsClient is current active websocket connection
      await wsClient.send "failure"
"""
  nimSsrWebsocketsRoutes* = """serve "127.0.0.1", 5000:
  # client-server messaging
  ws "/ws":
    await wsClient.send("hello")

  # used only when the websocket client is connected
  wsConnect:
    echo "New connection!"
    await wsClient.send("You're welcome!")
  
  # used when the websocket client triggers a protocol mismatch
  wsMismatchProtocol:
    echo "mismatch protocol"
  
  # used when the websocket client is disconnected
  wsClosed:
    echo "connect is closed"
  
  # used in other cases of websocket errors
  wsError:
    echo "unknown WS error"
"""
  nimAuthBasic* = """serve ... :
  @AuthBasic
  get "/test/basic-auth":
    echo username  # from @AuthBasic
    echo password  # from @AuthBasic
    return "Hello, {username}!"
"""
  nimAuthJWT* = """serve ... :
  # Authorization: JWT_TOKEN
  @AuthJWT(token)
  post "/test/jwt":
    if token.hasKey("name"):
      return "Hello, " & token["name"].node.str
    return "who are you???"
"""
  nimAuthBearerJWT* = """serve ... :
  # Authorization: Bearer JWT_TOKEN
  @AuthBearerJWT(token)
  post "/test/jwt":
    if token.hasKey("name"):
      return "Hello, " & token["name"].node.str
    return "who are you???"
"""
  nimCachedDecorator* = """
model TestModel:
  username: string
  password: string

serve ... :
  @Cached  # Expires in 60 seconds by default
  get "/cached/{i:int}":
    await sleepAsync(1000)
    if true:
      if (query?test) == "hello":
        return 100
    echo query?one
    return i
  
  @Cached(120)  # Will expires in 120 seconds
  get "/cached/{x}":
    await sleepAsync(1000)
    if hasKey(query, "key"):
      return query["key"]
    await sleepAsync(1000)
    return x
  
  @Cached(expires = 200)  # Will expires in 200 seconds
  post "/cached/[m:TestModel]":
    await sleepAsync(1000)
    return m.username
"""
  nimRateLimitDecorator* = """serve ... :
  # default values is perSecond=60, fromAll=false
  @RateLimit(perSecond = 2, fromAll = true)
  get "/test/rate-limit":
    outHeaders["Test"] = 10
    outHeaders["HappyXHeader"] = "Hello"
    return "Hello, world!"
"""
