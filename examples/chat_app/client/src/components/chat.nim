import
  jscore,
  ./message,
  ../../../../../src/happyx


type
  Msg* = object
    text: cstring
    fromId: int


func initMsg*(text: cstring = "", fromId: int = 0): Msg =
  Msg(text: text, fromId: fromId)


var
  myMessage: cstring = ""
  myId = Math.round(Math.random() * 100)


buildJs:
  var webSocket = new WebSocket("ws://localhost:5123/listen")


component Chat:
  messageHistory: seq[State[Msg]] = @[]

  `template`:
    tDiv(class = "flex flex-col gap-2"):
      "You are {myId}"
      tDiv(class = "flex gap-4"):
        # Message text field
        tInput(id = "messageInput", class = "px-4 rounded-full bg-gray-200 w-96"):
          @input(event):
            # Update myMessage
            myMessage = $event.target.InputElement.value
        # Send button
        tButton(class = "px-4 bg-green-400 hover:bg-green-500 active:bg-green-600 transition-colors"):
          "send"
          @click:
            echo "Hi!"
            buildJs:
              # Send to WebSocket
              webSocket.send(JSON.stringify({
                "text": ~myMessage,
                "fromId": ~myId
              }))
            myMessage = ""
      # Dialog history
      tDiv(class = "flex flex-col gap-2 w-full"):
        for message in self.messageHistory:
          if (message->fromId) == myId:
            tDiv(class = "bg-blue-300 rounded-sm px-4 py-2 w-fit max-w-5xl"):
              component Message(text = (message->text), fromId = (message->fromId))
          else:
            tDiv(class = "bg-gray-300 rounded-sm px-4 py-2 self-end w-fit max-w-5xl"):
              component Message(text = (message->text), fromId = (message->fromId))
  
  `script`:
    var
      text: cstring
      fromId: int
    once:
      buildJs:
        function newMessage(event):
          const data = JSON.parse(event.data)
          echo data
          if data.response !== "failure":
            ~text = data.response.text
            ~fromId = data.response.fromId
            nim:
              self.messageHistory->add(remember initMsg(text, fromId))
              application.router()
        webSocket.onmessage = ~newMessage
    # func newMessage(event: any) =
    #   buildJs:
    #     echo "Hello, world!"
        # ~text = ~event.data.response.text
        # ~fromId = Number(~event.data.response.fromId)
      
