<div align="center">

![Happyx](https://user-images.githubusercontent.com/49402667/228402522-6dd72d4b-c21c-4acf-b1e2-8318b6e809da.png)
### Asynchronous web-framework written in Nim with ♥

![Nim language](https://img.shields.io/badge/>=1.4.0-1b1e2b?style=for-the-badge&logo=nim&logoColor=f1fa8c&label=Nim&labelColor=2b2e3b)

[![wakatime](https://wakatime.com/badge/user/eaf11f95-5e2a-4b60-ae6a-38cd01ed317b/project/bbd13748-36e6-4383-ac40-9c4e72c060d1.svg?style=for-the-badge)](https://wakatime.com/badge/user/eaf11f95-5e2a-4b60-ae6a-38cd01ed317b/project/bbd13748-36e6-4383-ac40-9c4e72c060d1)

[![Testing](https://github.com/HapticX/happyx/actions/workflows/tests.yml/badge.svg?style=for-the-badge)](https://github.com/HapticX/happyx/actions/workflows/tests.yml)

</div>


# Why HappyX? 💁‍♀️
Because it's simple to use 🙂

## Why not Jester? 🤔
Jester doesn't provides some features that provides Happyx.

## Features ⚡
- Support `asynchttpserver` as default http server.
- Support `httpx` via `-d:httpx` as alternative HTTP server.
- Support `SPA` on `JS` backend and `SSG` on other backends.
- Building HTML with `buildHtml` macro.
- Routing `SPA`/`SSG` with `routes` marco.
- Logging with `-d:debug`.

# Get Started 👨‍🔬

## Installing 📥
### Via Nimble
```bash
nimble install happyx
```
### Via GitHub
```bash
nimble install https://github.com/HapticX/happyx
```

## Usage ▶
```nim
import happyx

initServer:
  var server = newServer()

  server.routes:
    # By default routing takes any request method
    "/":
      req.answer("Hello, world!")
    
    # You can use let variables in the routes!
    "/user{id:int}":
      req.answer(fmt"Hello, user with ID {id}!")
  
  server.start()
```
## Run 💻
### Default
```bash
nim c -r -d:ssl -d:debug main
```
### Httpx
```bash
nim c -r -d:ssl -d:debug -d:httpx main
```

## SPA
`index.html`
```html
<html>
  <head>
  </head>
  <body>
    <div id="app"></div>
    <script src="main.js"></script>
  </body>
</html>
```
`main.nim`
```nim
import happyx

var app = newApp()
app.routes:
  "/user{userId:int}":
    buildHtml(h1):
      "User ID is {userId}"
app.start()
```
### Run 💻
```bash
nim js main
```


# Contributing 🌀
See [Contributing.md](https://github.com/HapticX/happyx/blob/master/.github/CONTRIBUTING.md) for more information
