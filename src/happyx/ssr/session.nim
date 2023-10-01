## # Session 🔌
## 
## Provides working with sessions
##
import
  strutils,
  random,
  tables,
  times,
  sequtils,
  cookies,
  options,
  ../core/[constants]


when enableHttpBeast:
  import httpbeast
elif enableHttpx:
  import httpx
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
  result = "hpxs_"
  for i in 0..sessionIdLength:
    result &= sessionIdChars[rand(sessionIdChars.len-1)]


proc getSession*(req: Request, host: string, cookies: var seq[string], timeout: int64 = 0): Session {.gcsafe, inline.} =
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
  when declared(req) and declared(hostname):
    getSession(req, hostname, cookies, 0)
  else:
    raise newException(ValueError, "createSession should be called in server routes scope!")
    0


template startSession*(timeout: int64): Session =
  when declared(req) and declared(hostname):
    getSession(req, hostname, cookies, timeout)
  else:
    raise newException(ValueError, "createSession should be called in server routes scope!")
    0


template closeSession*(sessionId: string) =
  {.gcsafe.}:
    registeredSessions.del(hostname)


template closeSession*(session: Session) =
  {.gcsafe.}:
    var key = ""
    for k in registeredSessions.keys():
      if registeredSessions[k].id == session.id:
        key = k
        break
    if key != "":
      registeredSessions.del(key)
