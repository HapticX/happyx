import
  ./utils


import illwill except
  fgBlue, fgGreen, fgMagenta, fgRed, fgWhite, fgYellow, bgBlue,
  bgGreen, bgMagenta, bgRed, bgWhite, bgYellow, resetStyle


proc devCommand*(host: string = "127.0.0.1", port: int = 5000,
                 reload: bool = false): int =
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
    styledEcho fgRed, emoji["❌"](), " SSR/SSG projects not available in the dev mode."
    styledEcho fgMagenta, emoji["💡"](), " Make SSR/SSG dev mode and send Pull Request if you want!"
    shutdownCli()
    return QuitSuccess

  # Start server for SPA
  styledEcho "⚡ Server launched at ", fgGreen, styleUnderscore, "http://", host, ":", $port, fgWhite
  openDefaultBrowser("http://" & host & ":" & $port & "/#/")

  serve host, port:
    get "/":
      let f = open(getCurrentDir() / project.srcDir / "index.html")
      var data = f.readAll()
      f.close()
      data = data.replace(
        "</body>",
        "<script>" &
        fmt"let socket = new WebSocket('ws://{host}:{port}/hcr');" &
        "\nsocket.onmessage = (event) => {\n" &
        "  if(event.data === 'true'){\n    window.location.reload();\n  }\n" &
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
          await wsClient.send("true")
        else:
          await wsClient.send("false")
    
    get "/{file:path}":
      var result = ""
      let path = getCurrentDir() / project.srcDir / file.replace('\\', '/').replace('/', DirSep)
      echo "File: ", file
      echo "Path: ", path
      if fileExists(path):
        await req.answerFile(path, forceResponse = true)
  shutdownCli()
  QuitSuccess