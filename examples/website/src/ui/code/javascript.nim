const
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
  javaScriptProject* = """project/
├─ node_modules/
├─ src/
│  ├─ index.js
├─ .gitignore
├─ package.json
├─ README.md
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
  jsPathParamsSsr* = """const app = new Server();

app.get("/user/id{userId}", (req) => {
  console.log(req.params.userId);
  return {'response': userId};
});
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