## # Request Handlers
## 
import
  ../core/constants,
  httpcore


when defined(napibuild):
  import ./server

  # NodeJS Request Handlers
  template handleApiDoc*(self: Server) =
    for route in self.routes:
      if not route.hasHttpMethod(@["MIDDLEWARE", "NOTFOUND"]):
        let routeData = handleRoute(route.path)
        if route.httpMethod == @["STATICFILE"]:
          apiDocData.add(newApiDocObject(
            @["GET"],
            "Fetch file from directory: " & route.purePath,
            routeData.path,
            routeData.pathParams,
            routeData.requestModels,
          ))
        else:
          apiDocData.add(newApiDocObject(
            route.httpMethod,
            route.docs,
            routeData.path,
            routeData.pathParams,
            routeData.requestModels,
          ))
  
  template handleNodeRequest*(self: Server, req: Request, urlPath: string) =
    var reqResponded {.inject.} = false
    for route in self.routes:
      if (
          (@["NOTFOUND"] == route.httpMethod and not(reqResponded)) or
          (
            @["MIDDLEWARE"] == route.httpMethod or
            (
              (contains(route.httpMethod, $get(req.httpMethod)) and route.pattern in urlPath) or
              (hasHttpMethod(route, @["STATICFILE", "WEBSOCKET"]) and route.pattern in urlPath)
            )
          )
        ):
        {.gcsafe.}:
          if @["STATICFILE"] == route.httpMethod:
            var routeData = handleRoute(route.path)
            let
              founded_regexp_matches = findAll(urlPath, route.pattern)
              funcParams = getRouteParams(routeData, founded_regexp_matches, urlPath, force = true)
              fileName = $funcParams["file"]
              file =
                if not route.purePath.endsWith("/") and not fileName.startsWith("/"):
                  route.purePath / fileName
                else:
                  route.purePath & fileName
            if fileExists(file):
              await req.answerFile(file)
              reqResponded = true
          elif @["WEBSOCKET"] == route.httpMethod:
            var
              wsClient = await req.newWebSocket()
              handler = getProperty(getGlobal(), route.handler)
              wsConnection = wsClient.newWebSocketObj("")
              wsId = registerWsClient(wsConnection)
            var httpRequest = toObject({
              "path": urlPath,
              "websocketId": wsId,
              "data": wsConnection.data,
              "state": $(wsConnection.state)
            })
            echo httpRequest
            try:
              wsConnection.state = wssConnect
              httpRequest["state"] = jsObj($wsConnection.state)
              discard callFunction(handler, [httpRequest], getGlobal())
              wsConnection.state = wssOpen
              httpRequest["state"] = jsObj($wsConnection.state)
              discard callFunction(handler, [httpRequest], getGlobal())
              while wsClient.readyState == Open:
                let wsData = await wsClient.receiveStrPacket()
                wsConnection.data = wsData
                httpRequest["state"] = jsObj($wsConnection.state)
                httpRequest["data"] = jsObj(wsConnection.data)
                discard callFunction(handler, [httpRequest], getGlobal())
            except WebSocketClosedError:
              wsConnection.state = wssClose
            except WebSocketHandshakeError:
              logging.error("Invalid WebSocket handshake. Headers haven't Sec-WebSocket-Version!")
              wsConnection.state = wssHandshakeError
            except WebSocketProtocolMismatchError:
              logging.error(fmt"Socket tried to use an unknown protocol: {getCurrentExceptionMsg()}")
              wsConnection.state = wssMismatchProtocol
            except WebSocketError:
              logging.error(fmt"Unexpected socket error: {getCurrentExceptionMsg()}")
              wsConnection.state = wssError
            except Exception:
              logging.error(fmt"Unexpected error: {getCurrentExceptionMsg()}")
              wsConnection.state = wssError
            httpRequest["data"] = jsObj("")
            httpRequest["state"] = jsObj($wsConnection.state)
            discard callFunction(handler, [httpRequest], getGlobal())
            unregisterWsClient(wsId)
            wsClient.close()
            reqResponded = true
          else:
            let queryFromUrl = block:
              let val = split(req.path.get(), "?")
              if len(val) >= 2:
                val[1]
              else:
                ""
            let query = parseQuery(queryFromUrl)
            var routeData = handleRoute(route.path)
            var handler = getProperty(getGlobal(), route.handler)
            let founded_regexp_matches = findAll(urlPath, route.pattern)
            # Setup HttpRequest
            var httpRequest = toObject({
              "path": urlPath,
              "queries": query.toJsObj(),
              "headers": req.headers.get().toJsObj(),
              "cookies": inCookies.toJsObj(),
              "hostname": req.ip,
              "method": $req.httpMethod.get(),
              "reqId": req.registerRequest()
            })
            var params: RouteObject
            if req.body.isSome():
              httpRequest["body"] = jsObj(req.body.get())
              params = getRouteParams(routeData, founded_regexp_matches, urlPath, @[], req.body.get(), force = true)
            else:
              params = getRouteParams(routeData, founded_regexp_matches, urlPath, @[], force = true)
            httpRequest["params"] = params
            # Get function params
            var response = callFunction(handler, [httpRequest], getGlobal())
            if @["MIDDLEWARE"] != route.httpMethod:
              case response.kind
              of napi_undefined:
                discard
              of napi_null:
                req.answer("null")
                reqResponded = true
              of napi_string:
                req.answer(response.getStr)
                reqResponded = true
              of napi_number:
                req.answer($response.getInt)
                reqResponded = true
              of napi_boolean:
                req.answer($response.getBool)
                reqResponded = true
              of napi_object:
                # When object is response
                if response.hasOwnProperty("$data"):
                  let
                    resp = response["$data"]
                    httpCode = HttpCode(if response.hasOwnProperty("$code"): response["$code"].getInt else: 200)
                    headers =
                      if response.hasOwnProperty("$headers"):
                        let json = tryGetJson(response["$headers"])
                        json.toHttpHeaders
                      else:
                        newHttpHeaders([
                          ("Content-Type", "text/plain; charset=utf-8")
                        ])
                  case resp.kind
                  of napi_undefined:
                    req.answer("", httpCode, headers)
                    reqResponded = true
                  of napi_null:
                    req.answer("null", httpCode, headers)
                    reqResponded = true
                  of napi_string:
                    req.answer(resp.getStr, httpCode, headers)
                    reqResponded = true
                  of napi_number:
                    req.answer($resp.getInt, httpCode, headers)
                    reqResponded = true
                  of napi_boolean:
                    req.answer($resp.getBool, httpCode, headers)
                    reqResponded = true
                  of napi_object:
                    let stringRepr = $napiCall("JSON.stringify", [resp]).getStr
                    try:
                      let json = parseJson(stringRepr)
                      req.answerJson(json, httpCode, headers)
                      reqResponded = true
                    except JsonParsingError:
                      req.answer(stringRepr, httpCode, headers)
                      reqResponded = true
                  else:
                    discard
                else:
                  # Object is just JSON
                  let stringRepr = $napiCall("JSON.stringify", [response]).getStr
                  try:
                    let json = parseJson(stringRepr)
                    req.answerJson(json)
                    reqResponded = true
                  except JsonParsingError:
                    req.answer(stringRepr)
                    reqResponded = true
              else:
                discard
      if reqResponded:
        return


elif exportJvm:
  import
    jnim,
    jnim/private/[jni_wrapper],
    ./server

  template handleJvmRequest*(self: server.Server, req: Request, urlPath: string) =
    var reqResponded {.inject.} = false
    for route in self.routes:
      if (
        (@["NOTFOUND"] == route.httpMethod and not(reqResponded)) or
        (
          @["MIDDLEWARE"] == route.httpMethod or
          (
            (contains(route.httpMethod, $req.httpMethod.get()) and route.pattern in urlPath) or
            (hasHttpMethod(route, @["STATICFILE", "WEBSOCKET"]) and route.pattern in urlPath)
          )
        )
      ):
        {.gcsafe.}:
          let request = initHttpRequest(
            $req.httpMethod.get(),
            req.body.get(),
            req.path.get(),
            req.ip(),
            req
          )
          if route.httpMethod.len > 0 and route.httpMethod[0] == "STATICFILE":
            let
              routeData = handleRoute(route.path)
              founded_regexp_matches = findAll(urlPath, route.pattern)
              funcParams = getRouteParams(routeData, founded_regexp_matches, urlPath, force = true)
              fileName = $funcParams.objVal["file"].strVal
              extensions =
                if route.httpMethod.len > 1:
                  route.httpMethod[1..^1]  # file extensions
                else:
                  @[]
              file =
                if not route.purePath.endsWith($DirSep) and not fileName.startsWith($DirSep):
                  route.purePath / fileName
                else:
                  route.purePath & fileName
              splitted = file.split(".")
              ext = splitted[^1]
            if fileExists(file):
              if extensions.len == 0 or ext in extensions or splitted.len == 1:
                await req.answerFile(file)
                reqResponded = true
          elif @["WEBSOCKET"] == route.httpMethod:
            var
              wsClient = await req.newWebSocket()
              handler = route.handler
              wsConnection = wsClient.newWebSocketObj("")
              wsId = wsConnection.id
            try:
              wsConnection.state = wssConnect
              env.CallVoidMethod(env, handler.class, handler.methodId, env.toJava(wsConnection))
              wsConnection.state = wssOpen
              env.CallVoidMethod(env, handler.class, handler.methodId, env.toJava(wsConnection))
              while wsClient.readyState == Open:
                let wsData = await wsClient.receiveStrPacket()
                wsConnection.data = wsData
                env.CallVoidMethod(env, handler.class, handler.methodId, env.toJava(wsConnection))
            except WebSocketClosedError:
              wsConnection.state = wssClose
            except WebSocketHandshakeError:
              logging.error("Invalid WebSocket handshake. Headers haven't Sec-WebSocket-Version!")
              wsConnection.state = wssHandshakeError
            except WebSocketProtocolMismatchError:
              logging.error(fmt"Socket tried to use an unknown protocol: {getCurrentExceptionMsg()}")
              wsConnection.state = wssMismatchProtocol
            except WebSocketError:
              logging.error(fmt"Unexpected socket error: {getCurrentExceptionMsg()}")
              wsConnection.state = wssError
            except Exception:
              logging.error(fmt"Unexpected error: {getCurrentExceptionMsg()}")
              wsConnection.state = wssError
            wsConnection.data = ""
            env.CallVoidMethod(env, handler.class, handler.methodId, env.toJava(wsConnection))
            wsClients.del(wsId)
            reqResponded = true
          elif not route.handler.isNil:
            let
              queryFromUrl = block:
                let val = split(req.path.get(), "?")
                if len(val) >= 2:
                  val[1]
                else:
                  ""
              # fetch queries
              query = parseQuery(queryFromUrl)
              # Declare RouteData
              routeData = handleRoute(route.path)
              # Unpack route path params
              founded_regexp_matches = urlPath.findAll(route.pattern)
              # get handler
              handler = route.handler
            # Get path params
            var params: RouteObject
            if req.body.isSome():
              params = getRouteParams(routeData, founded_regexp_matches, urlPath, @[], req.body.get(), force = true)
            else:
              params = getRouteParams(routeData, founded_regexp_matches, urlPath, @[], force = true)
            request.pathParam = params
            # Add queries into request.queries
            for k, v in query.pairs():
              request.queries.add(Query(key: k, value: v))
            # Add headers into request.headers
            for k, v in req.headers.get().pairs():
              request.headers.add(JavaHttpHeader(key: k, value: v))
            # Call callback
            let
              obj = env.CallObjectMethod(env, handler.class, handler.methodId, env.toJava(request))
              val = newJVMObject(obj)
            if request.answered:
              reqResponded = true
              break
            if obj.isNil or val.isNil:
              req.answer("null", Http500)
              reqResponded = true
            else:
              # Return raw data
              # Get object type
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
                reqResponded = true
              of "com.hapticx.response.BaseResponse":
                let o = cast[BaseResponse](val)
                req.answer(
                  $o.getData(),
                  HttpCode(o.getHttpCode().int),
                  env.toHttpHeaders(o.getHeaders())
                )
                reqResponded = true
              of "com.hapticx.response.HtmlResponse":
                let o = cast[HtmlResponse](val)
                req.answerHtml(
                  $o.getData(),
                  HttpCode(o.getHttpCode().int),
                  env.toHttpHeaders(o.getHeaders())
                )
                reqResponded = true
              of "com.hapticx.response.JsonResponse":
                let o = cast[JsonResponse](val)
                req.answerHtml(
                  $o.getData(),
                  HttpCode(o.getHttpCode().int),
                  env.toHttpHeaders(o.getHeaders())
                )
                reqResponded = true
              of "com.hapticx.response.FileResponse":
                let o = cast[FileResponse](val)
                await req.answerFile(
                  ($o.getData())[1..^1],
                  HttpCode(o.getHttpCode().int)
                )
                reqResponded = true
              else:
                req.answer(val.toStringRaw)
                reqResponded = true
      if reqResponded:
        break


elif exportPython:
  import ./server
  import nimpy

  template handlePythonRequest*(self: server.Server, req: Request, urlPath: string) =
    {.gcsafe.}:
      for route in self.routes:
        if (
          (@["NOTFOUND"] == route.httpMethod and not(reqResponded)) or
          (
            @["MIDDLEWARE"] == route.httpMethod or
            (
              (contains(route.httpMethod, $req.httpMethod.get()) and route.pattern in urlPath) or
              (hasHttpMethod(route, @["STATICFILE", "WEBSOCKET"]) and route.pattern in urlPath)
            )
          )
        ):
          if route.httpMethod.len > 0 and route.httpMethod[0] == "STATICFILE":
            let
              routeData = handleRoute(route.path)
              founded_regexp_matches = findAll(urlPath, route.pattern)
              funcParams = getRouteParams(routeData, founded_regexp_matches, urlPath, force = true)
              fileName = $funcParams["file"]
              extensions =
                if route.httpMethod.len > 1:
                  route.httpMethod[1..^1]  # file extensions
                else:
                  @[]
              file =
                if not route.purePath.endsWith($DirSep) and not fileName.startsWith($DirSep):
                  route.purePath / fileName
                else:
                  route.purePath & fileName
              splitted = file.split(".")
              ext = splitted[^1]
            if fileExists(file):
              if extensions.len == 0 or ext in extensions or splitted.len == 1:
                await req.answerFile(file)
                reqResponded = true
          else:
            let
              query = parseQuery(block:
                let val = split(req.path.get(), "?")
                if len(val) >= 2:
                  val[1]
                else:
                  ""
              )
            var
              # Declare RouteData
              routeData = handleRoute(route.path)
              # Declare Python Object (for function params)
              pyFuncParams: PyObject
            # Unpack route path params
            let
              founded_regexp_matches = urlPath.findAll(route.pattern)
              # Load path params into function parameters
              handlerParams = route.handlerParams
              funcParams = getRouteParams(
                routeData,
                founded_regexp_matches,
                urlPath,
                handlerParams,
                req.body.get()
              )
            # Add queries to function parameters
            for param in handlerParams:
              if not (py.None != callMethod(funcParams, "get", param.name)) and not param.reserved:
                funcParams[param.name] = case param.paramType
                  of "bool":
                    parseBoolOrJString(query.getOrDefault(param.name))
                  of "int":
                    parseIntOrJString(query.getOrDefault(param.name))
                  of "float":
                    parseFloatOrJString(query.getOrDefault(param.name))
                  else:
                    newJString(query.getOrDefault(param.name))
            # Create Pointer to Python Object
            let pFuncParams = funcParams.nimValueToPy()
            # Create Python Object
            pFuncParams.pyValueToNim(pyFuncParams)
            # Add HttpRequest to function parameters if required
            if handlerParams.hasHttpRequest:
              pyFuncParams[handlerParams.getParamName("HttpRequest")] = initHttpRequest(
                req.path.get(), $req.httpMethod.get(), req.headers.get(), req.body.get()
              )
            # Detect and create classes for request models
            for param in py.list(callMethod(funcParams, "keys")).to(JsonNode):
              let paramType = handlerParams.getParamType(param.getStr)
              if paramType in requestModelsHidden:
                var requestModel = requestModelsHidden[paramType].pyClass
                # Create Python class instance
                pyFuncParams[param] = requestModel.from_dict(requestModel, pyFuncParams[param])
            if route.httpMethod == @["WEBSOCKET"]:
              let wsClient = await newWebSocket(req)
              # Declare route handler
              var handler = route.handler
              let wsConnection = newWebSocketObj(wsClient, "")
              if handlerParams.hasParamType("WebSocket"):
                pyFuncParams[handlerParams.getParamName("WebSocket")] = wsConnection
              # Add function parameters to locals
              route.locals["funcParams"] = pFuncParams
              try:
                wsConnection.state = wssConnect
                processWebSocket(py, route.locals)
                wsConnection.state = wssOpen
                while wsClient.readyState == Open:
                  wsConnection.data = await wsClient.receiveStrPacket()
                  processWebSocket(py, route.locals)
              except WebSocketClosedError:
                wsConnection.state = wssClose
                processWebSocket(py, route.locals)
              except WebSocketHandshakeError:
                error("Invalid WebSocket handshake. Headers haven't Sec-WebSocket-Version!")
                wsConnection.state = wssHandshakeError
                processWebSocket(py, route.locals)
              except WebSocketProtocolMismatchError:
                error(fmt"Socket tried to use an unknown protocol: {getCurrentExceptionMsg()}")
                wsConnection.state = wssMismatchProtocol
                processWebSocket(py, route.locals)
              except WebSocketError:
                error(fmt"Unexpected socket error: {getCurrentExceptionMsg()}")
                wsConnection.state = wssError
                processWebSocket(py, route.locals)
              wsClient.close()
              reqResponded = true
              return
            
            # Add function parameters to locals
            route.locals["funcParams"] = pFuncParams
            let
              # Execute callback
              response = py.eval("func(**funcParams)", route.locals)
              # Handle response type
              responseType = response.getAttr("__class__").getAttr("__name__")
            # Respond
            if response != py.None:
              case $responseType
              of "dict":
                req.answerJson(response.to(JsonNode))
                reqResponded = true
              of "JsonResponseObj":
                let resp = response.to(JsonResponseObj)
                req.answerJson(resp.data, HttpCode(resp.statusCode), resp.headers.toHttpHeaders)
                reqResponded = true
              of "HtmlResponseObj":
                let resp = response.to(HtmlResponseObj)
                req.answerHtml(resp.data, HttpCode(resp.statusCode), resp.headers.toHttpHeaders)
                reqResponded = true
              of "FileResponseObj":
                let resp = response.to(FileResponseObj)
                await req.answerFile(resp.filename, HttpCode(resp.statusCode), resp.asAttachment)
                reqResponded = true
              else:
                req.answer($response)
                reqResponded = true
      if reqResponded:
        break
