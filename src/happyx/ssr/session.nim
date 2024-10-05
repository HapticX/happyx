## # Session 🔌
## 
## Provides working with sessions
##
## .. Note::
##    Uses a cookies for working with sessions
## 
import
  std/random,
  std/tables,
  std/times,
  std/sequtils,
  std/cookies,
  std/options,
  ../core/[constants]


when enableHttpBeast:
  import httpbeast
elif enableHttpx:
  import httpx
elif enableBuiltin:
  import ./core
elif enableMicro:
  import
    asynchttpserver,
    microasynchttpserver
else:
  import asynchttpserver


type
  Session* = object
    timeout*: int64  # 0 for infinity
    creationTimeUnix*: int64
    id*: string
    req*: Request


randomize()


const sessionIdChars = concat(toSeq('a'..'z'), toSeq('A'..'Z'), toSeq('0'..'9'))


var registeredSessions = newTable[string, Session]()


proc genSessionId*: string =
  ## Generates unique session ID like `hpxs_sndjKgij1n2niug9uDbdfVkn9er8Gh3n`
  runnableExamples:
    echo genSessionId()
  result = "hpxs_"
  for i in 0..sessionIdLength:
    result &= sessionIdChars[rand(sessionIdChars.len-1)]


proc getSession*(req: Request, host: string, cookies: var seq[string], timeout: int64 = 0): Session {.gcsafe, inline.} =
  ## Gets or creates a new session.
  ## 
  ## If session is exists and timeout is not expired then returns this session.
  ## 
  ## Creates a new session with `timeout` in other case.
  {.gcsafe.}:
    var currentTime = now().toTime().toUnix()
    if host in registeredSessions:
      var s = registeredSessions[host]
      # Check for timeout
      if s.timeout != 0 and currentTime - s.timeout >= s.creationTimeUnix:
        var newSession = Session(
          timeout: timeout, id: genSessionId(),
          req: req, creationTimeUnix: currentTime
        )
        if timeout <= 0:
          cookies.add(setCookie("hpxSession", newSession.id, secure = true, httpOnly = true))
        else:
          cookies.add(setCookie("hpxSession", newSession.id, secure = true, httpOnly = true, maxAge = some(timeout.int)))
        registeredSessions[host] = newSession
        return newSession
      else:
        return s
    else:
      var newSession = Session(
        timeout: timeout, id: genSessionId(),
        req: req, creationTimeUnix: currentTime
      )
      if timeout <= 0:
        cookies.add(setCookie("hpxSession", newSession.id, secure = true, httpOnly = true))
      else:
        cookies.add(setCookie("hpxSession", newSession.id, secure = true, httpOnly = true, maxAge = some(timeout.int)))
      registeredSessions[host] = newSession
      return newSession


template startSession*(): Session =
  ## Starts a new session or returns created if exists
  ## 
  ## See also [startSession template](#startSession.t,int64)
  when declared(req) and declared(hostname):
    getSession(req, hostname, outCookies, 0)
  else:
    raise newException(ValueError, "createSession should be called in server routes scope!")
    0


template startSession*(timeout: int64): Session =
  ## Starts a new session with timeout or returns created if exists or timeout is not expired
  ## 
  ## See also [startSession template](#startSession.t)
  when declared(req) and declared(hostname):
    getSession(req, hostname, outCookies, timeout)
  else:
    raise newException(ValueError, "createSession should be called in server routes scope!")
    0


template closeSession*(sessionId: string) =
  ## Closes active session
  ## 
  ## See also [closeSession template](#closeSession.t,Session)
  {.gcsafe.}:
    registeredSessions.del(hostname)


template closeSession*(session: Session) =
  ## Closes actove session
  ## 
  ## See also [closeSession template](#closeSession.t,string)
  {.gcsafe.}:
    var key = ""
    for k in registeredSessions.keys():
      if registeredSessions[k].id == session.id:
        key = k
        break
    if key != "":
      registeredSessions.del(key)
