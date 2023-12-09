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
    for pragma in s[4]:
      p.addPragma(pragma)
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


proc addRoute(env: JNIEnvPtr, self: Server, path: string, httpMethods: seq[string],
              requestCallback: jobject | JavaMethod,
              isHttpRequest: bool = true) {.inline.} =
  var
    p = path
    s = self
  when requestCallback is jobject:
    let jMethod =
      if requestCallback.isNil:
        nil
      elif not isHttpRequest:
        let
          jClass = env.GetObjectClass(env, requestCallback)
          methodId = env.GetMethodId(env, jClass, "onReceive", "(Lcom/hapticx/data/WSConnection;)V")
        env.initJavaMethod(jClass, methodId)
      else:
        let
          jClass = env.GetObjectClass(env, requestCallback)
          methodId = env.GetMethodId(env, jClass, "onRequest", "(Lcom/hapticx/data/HttpRequest;)Ljava/lang/Object;")
        env.initJavaMethod(jClass, methodId)
  else:
    let jMethod = requestCallback
  # Get root server
  while not s.parent.isNil():
    p = s.path & p
    s = s.parent
  let routeData = handleRoute(p)
  s.routes.add(initRoute(
    routeData.path, routeData.purePath, httpMethods, re2("^" & routeData.purePath & "$"), jMethod
  ))
  s.sortRoutes()


proc answerToReq(env: JNIEnvPtr, request: HttpRequest, val: JVMObject) {.async.}=
  let req = request.req
  request.answered = true

  case env.getObjectType(val)
  of "java.lang.Integer",
      "java.lang.Double",
      "java.lang.String",
      "java.lang.Boolean",
      "java.lang.Byte",
      "java.lang.Short",
      "java.lang.Long",
      "java.lang.Float",
      "java.lang.Char":
    req.answer(val.toStringRaw)
  of "com.hapticx.response.BaseResponse":
    let o = cast[BaseResponse](val)
    req.answer(
      $o.getData(),
      HttpCode(o.getHttpCode().int),
      env.toHttpHeaders(o.getHeaders())
    )
  of "com.hapticx.response.HtmlResponse":
    let o = cast[HtmlResponse](val)
    req.answerHtml(
      $o.getData(),
      HttpCode(o.getHttpCode().int),
      env.toHttpHeaders(o.getHeaders())
    )
  of "com.hapticx.response.JsonResponse":
    let o = cast[JsonResponse](val)
    req.answerHtml(
      $o.getData(),
      HttpCode(o.getHttpCode().int),
      env.toHttpHeaders(o.getHeaders())
    )
  of "com.hapticx.response.FileResponse":
    let o = cast[FileResponse](val)
    await req.answerFile(
      ($o.getData())[1..^1],
      HttpCode(o.getHttpCode().int)
    )
  else:
    req.answer(val.toStringRaw)


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
  
  proc websocket(serverId: jint, path: jstring, requestCallback: jobject) =
    ## Creates a new WS route at `path` with `callback`
    initJNI(env)
    env.addRoute(servers[serverId], $path, @["WEBSOCKET"], requestCallback, false)
  
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

  proc mount(serverId: jint, otherServerId: jint, path: jstring) =
    ## Registers sub application at `path`
    initJNI(env)
    servers[otherServerId].path = $path
    servers[otherServerId].parent = servers[serverId]
    # Get root server
    var
      self = servers[serverId]
      other = servers[otherServerId]
    for route in other.routes:
      env.addRoute(self, $path & route.purePath, route.httpMethod, route.handler)
  
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


# Work with WebSockets
nativeMethods com.hapticx.data~WSConnection:
  proc close(websocketId: jstring) =
    ## Close websocket connection
    initJNI(env)
    wsClients[$websocketId].ws.close()
  
  proc send(websocketId: jstring, data: jstring) =
    ## Sends data to websocket if available.
    initJNI(env)
    asyncCheck wsClients[$websocketId].ws.send($data)


# Work with BaseRequestClass
nativeMethods com.hapticx.data~BaseRequestModel:
  proc registerRequestModel(modelName: jstring, fields: jobject) =
    ## Registers a new request model
    initJNI(env)
    let fieldList = cast[List[Field]](newJVMObject(fields))
    var fields: seq[tuple[key, val: string]] = @[]

    for field in fieldList.toSeq():
      var fieldType = field.getType().getName()
      fieldType = case fieldType
        of "java.lang.String":
          "string"
        of "java.lang.Integer":
          "int"
        of "java.lang.Float":
          "float"
        of "java.lang.Boolean":
          "bool"
        else:
          fieldType.split(".")[^1].split("$")[^1]
      fields.add((
        field.getName(),
        fieldType
      ))

    requestModelsHidden.requestModels.add(
      RequestModelData(
        name: ($modelName).split(".")[^1].split("$")[^1],
        fields: fields
      )
    )



# Work with HttpRequest
nativeMethods com.hapticx.data~HttpRequest:
  proc answer(reqId: jstring, data: jobject) {.async.} =
    ## Registers a new request model
    initJNI(env)
    var
      val = newJVMObject(data)
      request = httpRequests[$reqId]
    await env.answerToReq(request, val)
