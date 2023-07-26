import
  ../../../../src/happyx


type
  Msg* = object
    text: string
    fromId: int


serve("127.0.0.1", 5123):
  wsConnect:
    echo "Connected"
  
  ws "/listen":
    try:
      echo wsData
      let message = wsData.parseJson().to(Msg)
      for connection in wsConnections:
        if connection.readyState == Open:
          await connection.send $(%*{
            "response": {
              "text": message.text,
              "fromId": message.fromId
            }
          })
    except JsonParsingError:
      await wsClient.send $(%*{
        "response": "failure"
      })
