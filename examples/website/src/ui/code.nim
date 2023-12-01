var
  ssrExample* = """import happyx

serve "127.0.0.1", 5000:
  get "/":
    return "Hello, world!"
"""
  spaExample* = """import happyx

appRoutes "app":
  "/":
    "Hello, world!"
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
  pathParamsSpaExample* = """import happyx

appRoutes "app":
  "/user{id:int}":
    "Hello! user {id}"
"""

  nimSsrHelloWorldExample* = """import happyx

# Serve app at http://localhost:5000
serve "127.0.0.1", 5000:
  # GET Method
  get "/":
    # Respond plaintext
    return "Hello, world"
"""

  nimSpaHelloWorldExample* = """import happyx

# Serve app at http://localhost:5000
appRoutes "app":
  # at example.com/#/
  "/":
    # plaintext
    "Hello, world"
"""

  pythonHelloWorldExample* = """from happyx import Server

# Create application
app = Server('127.0.0.1', 5000)


# GET method
@app.get('/')
def hello_world():
    # Respond plaintext
    return 'Hello, world!'


# start our app
app.start()
"""

  jsHelloWorldExample* = """import { Server } from "happyx";

// Create application
const app = new Server('127.0.0.1', 5000);


// GET method
app.get("/", (req) => {
  // Respond plaintext
  return "Hello, world!";
});


// start our app
app.start();
"""

  tsHelloWorldExample* = """import { Server, Request } from "happyx";

// Create application
const app = new Server('127.0.0.1', 5000);


// GET method
app.get("/", (req: Request) => {
  // Respond plaintext
  return "Hello, world!";
});


// start our app
app.start();
"""

  htmlHelloWorldExample* = """<!DOCTYPE html>
<html>
  <head>
    <title>Hello World App</title>
  </head>
  <body>
    <div id="app">
      <!-- Here will be your application -->
    </div>
    <!-- Nim script after compilation -->
    <script src="example.js"></script>
  </body>
</html>
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

  nimProjectSpa* = """project/
├─ src/
│  ├─ public/
│  │  ├─ icon.svg
│  ├─ components/
│  │  ├─ hello_world.nim
│  ├─ main.nim
│  ├─ index.html
├─ README.md
├─ .gitignore
├─ happyx.cfg
├─ project.nimble
"""

  pythonProject* = """project/
├─ main.py
├─ README.md
├─ .gitignore
"""
  javaScriptProject* = """project/
├─ node_modules/
├─ src/
│  ├─ index.js
├─ .gitignore
├─ package.json
├─ README.md
"""
  typeScriptProject* = """project/
├─ node_modules/
├─ src/
│  ├─ index.ts
├─ .gitignore
├─ package.json
├─ tsconfig.json
├─ README.md
"""
  nimSsrCalc* = """serve "127.0.0.1", 5000:
  get "/calc/{left:float}/{op}/{right:float}":
    case op
    of "+": return fmt"{left + right}"
    of "-": return fmt"{left - right}"
    of "/": return fmt"{left / right}"
    of "*": return fmt"{left * right}"
    else:
      statusCode = 404
      return "failure"
"""
  nimSpaCalc* = """appRoutes "app":
  "/calc/{left:float}/{op}/{right:float}":
    tDiv(class = "flex text-4xl justify-center items-center w-screen h-screen text-orange-200 bg-neutral-900"):
      if op == "+":
        {left + right}
      elif op == "-":
        {left - right}
      elif op == "/":
        {left / right}
      elif op == "*":
        {left * right}
      else:
        "failure"
"""
  pythonSsrCalc* = """@app.get('/calc/{left}/{op}/{right}')
def calculate(left: float, right: float, op: str):
    if op == "+":
        return left + right
    elif op == "-":
        return left - right
    elif op == "/":
        return left / right
    elif op == "*":
        return left * right
    else:
        return Response("failure", status_code=404)
"""
  javaScriptSsrCalc* = """app.get("/calc/{left}/{op}/{right}", (req) => {
  if req.params.op == "+":
    return req.params.left + req.params.right;
  elif req.params.op == "-":
    return req.params.left - req.params.right;
  elif req.params.op == "/":
    return req.params.left / req.params.right;
  elif req.params.op == "*":
    return req.params.left * req.params.right;
  req.answer("failure", code=404);
});
"""
  typeScriptSsrCalc* = """app.get("/calc/{left}/{op}/{right}", (req: Request) => {
  if req.params.op == "+":
    return req.params.left + req.params.right;
  elif req.params.op == "-":
    return req.params.left - req.params.right;
  elif req.params.op == "/":
    return req.params.left / req.params.right;
  elif req.params.op == "*":
    return req.params.left * req.params.right;
  req.answer("failure", code=404);
});
"""
  nimPathParamsSsr* = """serve "127.0.0.1", 5000:
  get "/user/id{userId:int}":
    ## here we can use userId as immutable variable
    echo userId
    return $userId
"""
  pythonPathParamsSsr* = """app = Server()

@app.get('/user/id{user_id}')
def handle(user_id: int):
    # Here we can use user_id
    print(user_id)
    return {'response': user_id}
"""
  jsPathParamsSsr* = """const app = new Server();

app.get("/user/id{userId}", (req) => {
  console.log(req.params.userId);
  return {'response': userId};
});
"""
  tsPathParamsSsr* = """const app = new Server();

app.get("/user/id{userId}", (req: Request) => {
  console.log(req.params.userId);
  return {'response': userId};
});
"""
  nimPathParamsSpa* = """appRoutes "app":
  "/user/id{userId:int}":
    ## here we can use userId as immutable variable
    tDiv:
      {userId}
"""
  nimCustomPathParamTypeSsr* = """import happyx

type MyType* = object
  first, second, third: string

proc parseMyType*(data: string): MyType =
  MyType(
    first: data[0], second: data[1], third: data[2]
  )

registerRouteParamType(
  "my_type",  # unique type identifier
  "\d\w\d",  # type pattern
  parseMyType  # proc/func that takes one string argument and returns any data
)

serve "127.0.0.1", 5000:
  get "/{i:my_type}":
    echo i.first
    echo i.second
    echo i.third
"""
  nimCustomPathParamTypeSpa* = """import happyx

type MyType* = object
  first, second, third: string

proc parseMyType*(data: string): MyType =
  MyType(
    first: data[0], second: data[1], third: data[2]
  )

registerRouteParamType(
  "my_type",  # unique type identifier
  "\d\w\d",  # type pattern
  parseMyType  # proc/func that takes one string argument and returns any data
)

appRoutes "app":
  "/{i:my_type}":
    echo i.first
    echo i.second
    echo i.third
"""
  pythonCustomRouteParamType* = """from happyx import Server, register_route_param_type


app = Server()


# Here is unique identifier, regex pattern and function/class object
@register_route_param_type("my_unique_id", r"\d+")
class MyUniqueIdentifier:
    def __init__(self, data: str):
        self.identifier = int(data)


@app.get("/registered/{data}")
def handle(data: MyUniqueIdentifier):
    print(data.identifier)
    return {'response': data.identifier}


app.start()
"""
  jsCustomRouteParamType* = """import { newPathParamType, Server } from "happyx";

const app = new Server();

// Here is unique identifier, RegExp pattern and function object
newPathParamType("my_unique_id", /\d+/, (data) => {
  return Number(data);
});

app.get("/registered/{data:my_unique_id}", (req) => {
  return req.params.data;
});

app.start()
"""
  tsCustomRouteParamType* = """import { newPathParamType, Server, Request } from "happyx";

const app = new Server();

// Here is unique identifier, RegExp pattern and function object
newPathParamType("my_unique_id", /\d+/, (data: string) => {
  return Number(data);
});

app.get("/registered/{data:my_unique_id}", (req: Request) => {
  return req.params.data;
});

app.start()
"""
  nimAssignRouteParamsSsr* = """import happyx

# declare path params
pathParams:
  paramName:  # assign param name
    type int  # param type
    optional  # param is optional
    mutable  # param is mutable variable
    default = 100  # default param value is 100


serve "127.0.0.1", 5000:
  # Use paramName
  get "/<paramName>":
    echo paramName
"""
  nimAssignRouteParamsSpa* = """import happyx

# declare path params
pathParams:
  paramName:  # assign param name
    type int  # param type
    optional  # param is optional
    mutable  # param is mutable variable
    default = 100  # default param value is 100


appRoutes "app":
  # Use paramName
  "/<paramName>":
    echo paramName
"""
  nimSpaRouting* = """import happyx


appRoutes "app":
  "/":
    "Welcome to home!"
    tButton:
      "go to '/bye'"
      @click:
        # When button clicked you'll redirect to /bye route
        route("/bye")
  "/bye":
    "Goodbye!"
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
  nimSpaHtmlTailwind* = """<!doctype html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <!-- You just should to include Tailwind via CDN! -->
  <!-- https://tailwindcss.com/docs/installation/play-cdn -->
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body>
  <div id="app"></div>
  <script src="main.js"></script>
</body>
</html>
"""
  nimSpaTailwind* = """import happyx


appRoutes "app":
  "/":
    tH1(class = "text-3xl font-bold underline"):
      "Hello, world!"
"""
  tailwindCli* = """hpx create --name:htmx_example --kind:SSR --templates --language:Nim
cd htmx_example
npm init
npm install -D tailwindcss
npx tailwindcss init
"""
  tailwindConfig* = """/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{html,htmx,nim,js}"],
  theme: {
    extend: {},
  },
  plugins: [],
}"""
  tailwindCssInput* = """@tailwind base;
@tailwind components;
@tailwind utilities;"""
  tailwindWatch* = "npx tailwindcss -i ./src/public/input.css -o ./src/public/output.css --watch"
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
  pySsrAdvancedHelloWorld* = """from happyx import Server, JsonResponse, Response


app = Server('127.0.0.1', 5000)


@app.get('/statusCode')
def test_only_status_code():
    return JsonResponse(
        {"response": "This page not working because I want it :p"},
        status_code = 404
    )


@app.get('/customHeaders')
def test_only_headers():
    return Response(
        0,
        headers = {
          "Backend-Server": "HappyX"
        }
    )


@app.get('/customCookies')
def test_only_cookies():
    return Response(
        0,
        headers = {
          "Set-Cookie": "bestFramework=HappyX!"
        }
    )


@app.get('/')
def test_all():
    return Response(
        1,
        headers = {
          "Reason": "Auth Failed",
          "Set-Cookie": "happyx-auth-reason=HappyX"
        },
        status_code = 401
    )


app.start()
"""
  jsSsrAdvancedHelloWorld* = """import {Server} from "happyx";


let server = new Server("127.0.0.1", 5000);


server.get("/statusCode"), (req) => {
  req.answer("This page not working because I want it :p", 404);
});


server.get("/customHeaders"), (req) => {
  req.answer(
    0, headers = {
      "Backend-Server": "HappyX"
    }
  );
});


server.get("/customCookies"), (req) => {
  req.answer(
    0, headers = {
      "Set-Cookie": "bestFramework=HappyX!"
    }
  );
});


server.get("/"), (req) => {
  req.answer(
    1, 401, headers = {
      "Reason": "Auth Failed",
      "Set-Cookie": "happyx-auth-reason=HappyX"
    }
  );
});


server.start()
"""

  tsSsrAdvancedHelloWorld* = """import {Server, Request} from "happyx";


let server = new Server("127.0.0.1", 5000);


server.get("/statusCode"), (req: Request) => {
  req.answer("This page not working because I want it :p", 404);
});


server.get("/customHeaders"), (req: Request) => {
  req.answer(
    0, headers = {
      "Backend-Server": "HappyX"
    }
  );
});


server.get("/customCookies"), (req: Request) => {
  req.answer(
    0, headers = {
      "Set-Cookie": "bestFramework=HappyX!"
    }
  );
});


server.get("/"), (req: Request) => {
  req.answer(
    1, 401, headers = {
      "Reason": "Auth Failed",
      "Set-Cookie": "happyx-auth-reason=HappyX"
    }
  );
});


server.start()
"""
  nimSsrAdditionalRoutes* = """import happyx


serve "127.0.0.1", 5000:
  middleware:
    echo req
  
  notfound:
    return "Oops, seems like this route is not available"

  staticDir "/path/to/directory" -> "directory"
"""
  pySsrAdditionalRoutes* = """from happyx import Server, HttpRequest


app = Server("127.0.0.1", 5000)

app.static("/path/to/directory", './directory')


@app.notfound()
def on_not_found():
    return "Oops, seems like this route is not available"


@app.middleware()
def on_not_found(req: HttpRequest):
    print(req.path())


app.start()
"""
  jsSsrAdditionalRoutes* = """import {Server} from "happyx";


const app = new Server("127.0.0.1", 5000)
app.static("/path/to/directory", './directory')


app.notfound(() => {
  return "Oops, seems like this route is not available";
});

app.middleware((req) => {
  console.log(req);
});

app.start()
"""
  tsSsrAdditionalRoutes* = """import {Server, Request} from "happyx";


const app = new Server("127.0.0.1", 5000)
app.static("/path/to/directory", './directory')


app.notfound(() => {
  return "Oops, seems like this route is not available";
});

app.middleware((req: Request) => {
  console.log(req);
});

app.start()
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


proc myCustomDecorator*(httpMethods: seq[string], path: string, statementList: NimNode) = 
  # This decorator will add
  #   echo "Hello from {path}"
  # as leading statement in route at compile-time
  statementList.insert(0, newCall("echo", newLit("Hello from " & path)))


# Register our decorator
static:
  regDecorator("OurDecorator", myCustomDecorator)


# Use it!
serve "127.0.0.1", 5000:
  @OurDecorator
  get "/":
    return 0
"""
  nimSpaReactivity* = """import happyx

# Create a new state
var x = remember 0


appRoutes "app":
  "/":
    "x value is {x}"
    tButton:
      "click me to increase"
      @click:
        # change state and rerender this
        x += 1
"""
  nimSpaComponentReactivity* = """import happyx


# create component
component Test:
  x: int = 0  # component state with default value
  `template`:
    "x value is {self.x}"
    tButton:
      "click me to increase"
      @click:
        # change state and rerender this
        self.x += 1


appRoutes "app":
  "/":
    # use components
    Test(x = 10)
    Test(x = 15)
    Test(x = 20)
"""
  nimSpaReacitivity1* = """import happyx

var x = remember 0

appRoutes "app":
  "/":
    "x counter: {x}"
    @click:
      x->inc()
"""
  nimSpaReacitivity2* = """import happyx

var x = remember newSeq[int]()

appRoutes "app":
  "/":
    "x sequence is {x}"
    @click:
      x->add(x.len())
"""
  nimSpaReacitivity3* = """import happyx

var
  x = remember newSeq[int]()
  y: State[seq[int]] = remember @[]
  z: State[int]
  w: State[string] = remember "Hello"

"""
  nimSpaReacitivity4* = """import happyx

var
  x = remember 0
  y = 10
  str = remember "Hello"

x += y
echo x  # 10, but x is still State[int]

x *= y
echo x  # x is 100 and again, x is State[int]

str &= ", world!"
echo str  # Hello, world!, but str is State[string]

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
  pyMongoDb1* = """from happyx import Server
from pymongo import MongoClient
from datetime import datetime


app = Server('127.0.0.1', 5000)
mongo_client = MongoClient()
db = mongo_client["happyx_test"]
users_coll = db["users"]
"""
  pyMongoDb2* = """
@app.post("/user/new")
def create_user():
    users_count = users_coll.count_documents({})
    result = users_coll.insert_one({
        "countId": users_count,
        "addedTime": datetime.utcnow()
    })
    return {"response": "success" if result.acknowledged else "failure"}
"""
  pyMongoDb3* = """
@app.get("/user/id{user_id:int}")
def read_user(user_id: int):
    user = users_coll.find_one({"countId": user_id})
    if user is None:
        return {"response": "failure"}
    else:
        return {
            "countId": user["countId"],
            "addedTime": user["addedTime"]
        }
"""
  pyMongoDb4* = """
@app.get("/users")
def read_users():
    users = users_coll.find()
    response = []
    for user in users:
        response.append({
            "countId": user["countId"],
            "addedTime": user["addedTime"]
        })
    return response


app.start()
"""
  pyMongoDb* = """from happyx import Server
from pymongo import MongoClient
from datetime import datetime


app = Server('127.0.0.1', 5000)
mongo_client = MongoClient()
db = mongo_client["happyx_test"]
users_coll = db["users"]


@app.post("/user/new")
def create_user():
    users_count = users_coll.count_documents({})
    result = users_coll.insert_one({
        "countId": users_count,
        "addedTime": datetime.utcnow()
    })
    return {"response": "success" if result.acknowledged else "failure"}


@app.get("/user/id{user_id:int}")
def read_user(user_id: int):
    user = users_coll.find_one({"countId": user_id})
    if user is None:
        return {"response": "failure"}
    else:
        return {
            "countId": user["countId"],
            "addedTime": user["addedTime"]
        }


@app.get("/users")
def read_users():
    users = users_coll.find()
    response = []
    for user in users:
        response.append({
            "countId": user["countId"],
            "addedTime": user["addedTime"]
        })
    return response


app.start()
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
