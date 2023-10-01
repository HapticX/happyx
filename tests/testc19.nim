import ../src/happyx


echo genSessionId()


serve "127.0.0.1", 5000:
  var sessionId: string = ""

  get "/":
    var session = startSession(10)  # in seconds

    sessionId = session.id
    return session.id

  get "/close":
    closeSession(sessionId)
    return {"response": "success"}
