import ../src/happyx


serve("127.0.0.1", 5000):
  get "/":
    let f = open("index.html")
    var data = f.readAll()
    f.close()
    data = data.replace(
      "</body>",
      "<script>" &
      fmt"let socket = new WebSocket('ws://127.0.0.1:5000/hcr');" &
      "\nsocket.onmessage = (event) => {\n" &
      "  if(event.data === 'true'){\n    window.location.reload();\n  }\n" &
      "};\n\n" &
      "function intervalSending(){\n  socket.send('reload')\n}\n\n" &
      "setInterval(intervalSending, 100);\n" &
      "</script></body>"
    )
    req.answerHtml(data)
  
  wsConnect:
    echo "connected"
    await wsClient.send("You're welcome!")

  ws "/hcr":
    if wsData == "reload" and wsClient.readyState == Open:
      await wsClient.send("true")

  "/{file:path}":
    var result = ""
    let path = getCurrentDir() / file
    if fileExists(path):
      let
        f = open(path)
        data = f.readAll()
      f.close()
      result = data
    req.answer(result)