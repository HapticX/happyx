import ../src/happyx


echo genSessionId()


model User:
  username: string
  id: int


serve "127.0.0.1", 5000:
  var sessionId: string = ""

  get "/":
    ## Opens or loads a new session with timeout 10 seconds
    ## 
    ## @openapi {
    ##  operationId = startSession
    ##  summary = Открыть сессию
    ## 
    ##  @params {
    ##    username : integer - юзернейм пользователя
    ##  }
    ## }
    var session = startSession(10)  # in seconds

    sessionId = session.id
    return session.id

  get "/user{userId:int}":
    ## Shows user at ID {id}
    ## 
    ## @openapi {
    ##  operationId = getUserById
    ##  summary = Профиль
    ## }
    return fmt"Hello, {userId}"

  post "/user[u:User]":
    return 0

  get "/close":
    ## Closes current session
    ## 
    ## @openapi {
    ##  operationId = closeSession
    ##  summary = Закрыть сессию
    ## }
    closeSession(sessionId)
    return {"response": "success"}
