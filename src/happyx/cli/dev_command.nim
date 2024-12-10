import
  ./utils,
  regex


import illwill except
  fgBlue, fgGreen, fgMagenta, fgRed, fgWhite, fgYellow, bgBlue,
  bgGreen, bgMagenta, bgRed, bgWhite, bgYellow, resetStyle


proc devCommand*(host: string = "127.0.0.1", port: int = 5000,
                 reload: bool = false, browser: bool = false): int =
  ## Serve
  var
    project = compileProject()
    needReload = false
    godEyeData = GodEyeData(
      project: addr project,
      needReload: addr needReload,
    )
  
  if project.error.len > 0:
    shutdownCli()
    return QuitFailure

  if reload:
    initLock(L)
    createThread(godEyeThread, godEye, addr godEyeData)

  # Launch SSR app
  if project.projectType in [ptSSG, ptSSR]:
    var f = open(getCurrentDir() / project.srcDir / (project.mainFile & ".nim"))
    var data = f.readAll()
    f.close()
    var m: RegexMatch2
    discard data.find(re2("serve\\s*\\(?\\s*\\\"([^\\\"]+)\\\"\\s*,?\\s*(\\d+)"), m)
    let
      host = data[m.group(0)]
      port = data[m.group(1)]
    styledEcho "⚡ Server launched at ", fgGreen, styleUnderscore, "http://" & host & ":" & port, fgWhite
    if browser:
      openDefaultBrowser("http://" & host & ":" & port & "/")
    while true:
      styledEcho fgYellow, "if you want to quit from program, please input [q] char"
      if stdin.readChar() == 'q':
        break
    if not project.process.isNil:
      styledEcho fgYellow, "Quit from programm: terminate process"
      let id = project.process.processID()
      when defined(windows):
        discard execCmd(fmt"taskkill /F /PID {id}")
      elif defined(linux):
        discard execCmd(fmt"kill {id}")
      elif defined(macos) or defined(macosx):
        discard execCmd(fmt"kill -9 {id}")
    styledEcho fgYellow, "Quit from programm ..."
    shutdownCli()
    return QuitSuccess

  # Start server for SPA
  styledEcho "⚡ Server launched at ", fgGreen, styleUnderscore, "http://127.0.0.1:", $port, fgWhite
  openDefaultBrowser("http://127.0.0.1:" & $port & "/")

  serve host, port:
    get "/":
      let f = open(getCurrentDir() / project.srcDir / "index.html")
      var data = f.readAll()
      f.close()
      data = data.replace(
        "</body>",
        "<script>" &
        fmt"let socket = new WebSocket('ws://' + window.location.host + '/hcr');" &
        "\nsocket.onmessage = (event) => {\n" &
        "  if(event.data === '1'){\n    window.location.reload();\n  }\n" &
        "};\n\n" &
        "function intervalSending(){\n  socket.send('reload')\n}\n\n" &
        "setInterval(intervalSending, 1000);\n" &
        "</script></body>"
      )
      req.answerHtml(data)
    
    ws "/hcr":
      if wsData == "reload":
        if needReload:
          needReload = false
          await wsClient.send("1")
        else:
          await wsClient.send("0")
    
    get "/{file:path}":
      var result = ""
      let path = getCurrentDir() / project.srcDir / file.replace('\\', '/').replace('/', DirSep)
      echo "File: ", file
      echo "Path: ", path
      if fileExists(path):
        await req.answerFile(path, forceResponse = true)
  shutdownCli()
  QuitSuccess
