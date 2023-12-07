import
  jnim,
  jnim/private/[jni_wrapper, jni_export, jni_api],
  jnim/java/[lang, util],
  ../ssr/[server, request_models, session, utils],
  ../core/[constants, queries, exceptions],
  ../routing/[routing, mounting],
  ./java_types,
  ../routing/[routing],
  strutils,
  unicode,
  tables,
  macros,
  nimja,
  sugar


macro nativeMethods(class: untyped, body: untyped) =
  if class.kind != nnkInfix or class[0] != ident"~":
    return
  result = newStmtList()
  let package = ($class[1].toStrLit).replace(".", "_")
  for s in body:
    if s.kind != nnkProcDef:
      continue
    var p = newProc(
      postfix(ident("Java_" & package & "_" & $class[2] & "_" & $s[0]), "*"),
      [
        s.params[0],
        newIdentDefs(ident"env", ident"JNIEnvPtr"),
        newIdentDefs(ident"obj", ident"jobject"),
      ]
    )
    p.body = s.body
    if p.body[0].kind != nnkCommentStmt:
      # p.body.insert(0, newCall("initJNI", ident"env"))
      p.body.insert(0, newCall("setupForeignThreadGc"))
    else:
      # p.body.insert(1, newCall("initJNI", ident"env"))
      p.body.insert(1, newCall("setupForeignThreadGc"))
    for i in 1..s.params.len-1:
      p.params.add(s.params[i])
    # dynlib pragmas
    p.addPragma(ident"cdecl")
    p.addPragma(ident"exportc")
    p.addPragma(ident"dynlib")
    result.add(p)
  echo result.toStrLit


var
  servers = newTable[jint, Server]()
  uniqueServerId: jint = 0



proc sortRoutes(self: Server) {.inline.} =
  ## Sorts routes:
  ## Firstly middlewares, secondary is routes and after notfounds 
  var
    middlewares: seq[Route] = @[]
    routes: seq[Route] = @[]
    notfounds: seq[Route] = @[]
  for i in self.routes:
    if i.httpMethod == @["MIDDLEWARE"]:
      middlewares.add(i)
    elif i.httpMethod == @["NOTFOUND"]:
      notfounds.add(i)
    else:
      routes.add(i)
  self.routes = middlewares
  for i in routes:
    self.routes.add(i)
  for i in notfounds:
    self.routes.add(i)


proc addRoute(env: JNIEnvPtr, self: Server, path: string, httpMethods: seq[string], requestCallback: jobject) {.inline.} =
  var
    p = path
    s = self
  let jMethod =
    if requestCallback.isNil:
      nil
    else:
      let
        jClass = env.GetObjectClass(env, requestCallback)
        methodId = env.GetMethodId(env, jClass, "onRequest", "(Lcom/hapticx/data/HttpRequest;)Ljava/lang/Object;")
      env.initJavaMethod(jClass, methodId)
  # Get root server
  while not s.parent.isNil():
    p = s.path & p
    s = s.parent
  let routeData = handleRoute(p)
  s.routes.add(initRoute(
    routeData.path, routeData.purePath, httpMethods, re2("^" & routeData.purePath & "$"), jMethod
  ))
  s.sortRoutes()


nativeMethods com.hapticx~Server:
  proc createServer(host: jstring, port: jint): jint =
    ## Creates a new server with host and port
    initJNI(env)
    inc uniqueServerId
    servers[uniqueServerId] = newServer($host, port.int)
    return uniqueServerId
  
  proc get(serverId: jint, path: jstring, requestCallback: jobject) =
    ## Creates a new GET route at `path` with `callback`
    initJNI(env)
    env.addRoute(servers[serverId], $path, @["GET"], requestCallback)
  
  proc post(serverId: jint, path: jstring, requestCallback: jobject) =
    ## Creates a new POST route at `path` with `callback`
    initJNI(env)
    env.addRoute(servers[serverId], $path, @["POST"], requestCallback)
  
  proc put(serverId: jint, path: jstring, requestCallback: jobject) =
    ## Creates a new POST route at `path` with `callback`
    initJNI(env)
    env.addRoute(servers[serverId], $path, @["PUT"], requestCallback)
  
  proc delete(serverId: jint, path: jstring, requestCallback: jobject) =
    ## Creates a new DELETE route at `path` with `callback`
    initJNI(env)
    env.addRoute(servers[serverId], $path, @["DELETE"], requestCallback)
  
  proc purge(serverId: jint, path: jstring, requestCallback: jobject) =
    ## Creates a new PURGE route at `path` with `callback`
    initJNI(env)
    env.addRoute(servers[serverId], $path, @["PURGE"], requestCallback)
  
  proc link(serverId: jint, path: jstring, requestCallback: jobject) =
    ## Creates a new LINK route at `path` with `callback`
    initJNI(env)
    env.addRoute(servers[serverId], $path, @["LINK"], requestCallback)
  
  proc unlink(serverId: jint, path: jstring, requestCallback: jobject) =
    ## Creates a new UNLINK route at `path` with `callback`
    initJNI(env)
    env.addRoute(servers[serverId], $path, @["UNLINK"], requestCallback)
  
  proc copy(serverId: jint, path: jstring, requestCallback: jobject) =
    ## Creates a new COPY route at `path` with `callback`
    initJNI(env)
    env.addRoute(servers[serverId], $path, @["COPY"], requestCallback)
  
  proc head(serverId: jint, path: jstring, requestCallback: jobject) =
    ## Creates a new HEAD route at `path` with `callback`
    initJNI(env)
    env.addRoute(servers[serverId], $path, @["HEAD"], requestCallback)
  
  proc route(serverId: jint, path: jstring, methods: jobject, requestCallback: jobject) =
    ## Creates a new route at `path` with `callback`
    initJNI(env)
    var methodsList = (cast[List[string]](newJVMObject(methods))).toSeq()
    env.addRoute(servers[serverId], $path, methodsList, requestCallback)
  
  proc middleware(serverId: jint, requestCallback: jobject) =
    ## Creates a new middleware for server with `callback`
    initJNI(env)
    env.addRoute(servers[serverId], "", @["MIDDLEWARE"], requestCallback)
  
  proc notFound(serverId: jint, requestCallback: jobject) =
    ## Creates a new middleware for server with `callback`
    initJNI(env)
    env.addRoute(servers[serverId], "", @["NOTFOUND"], requestCallback)

  proc staticDirectory(serverId: jint, path: jstring, directory: jstring, extensions: jobject) =
    ## Registers public folder
    initJNI(env)
    var
      p = $path
      s = servers[serverId]
    while not s.parent.isNil():
      p = s.path & p
      s = s.parent
    if not p.endsWith("/"):
      p &= "/"
    p &= "{file:path}"
    let routeData = handleRoute(p)
    if extensions.isNil:
      servers[serverId].routes.add(initRoute(
        p, $directory, @["STATICFILE"], re2("^" & routeData.purePath & "$"), nil
      ))
    else:
      var extensionsList = (cast[List[string]](newJVMObject(extensions))).toSeq()
      extensionsList.insert("STATICFILE", 0)
      servers[serverId].routes.add(initRoute(
        p, $directory, extensionsList, re2("^" & routeData.purePath & "$"), nil
      ))
  
  proc startServer(serverId: jint) =
    ## Starts a server at host and port
    {.gcsafe.}:
      var self = servers[serverId]
      if not self.parent.isNil():
        raise newException(
          HpxAppRouteDefect, fmt"Server that you start shouldn't be mounted!"
        )
    serve self.address, self.port:
      discard
