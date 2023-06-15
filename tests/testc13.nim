import ../src/happyx


serve("127.0.0.1", 5123):
  ws "/":
    echo wsData
    await wsClient.send("i")
    for client in wsConnections:
      await client.send("hi")
  
  wsClosed:
    echo "closed"
  
  wsConnect:
    echo "connect"
