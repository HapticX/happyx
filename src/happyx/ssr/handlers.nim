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
    var reqResponded = false
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
        {.cast(gcsafe).}:
          if @["MIDDLEWARE"] != route.httpMethod:
            reqResponded = true
          if @["STATICFILE"] == route.httpMethod:
            var routeData = handleRoute(route.path)
            let
              founded_regexp_matches = findAll(urlPath, route.pattern)
              funcParams = getRouteParams(routeData, founded_regexp_matches, urlPath, force = true)
              fileName = $funcParams["file"]
              file =
                if not route.purePath.endsWith("/") and not fileName.startsWith("/"):
                  route.purePath & "/" & fileName
                else:
                  route.purePath & fileName
            if fileExists(file):
              await req.answerFile(file)
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
              of napi_string:
                req.answer(response.getStr)
              of napi_number:
                req.answer($response.getInt)
              of napi_boolean:
                req.answer($response.getBool)
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
                    req.answer("", httpCode, headers);
                  of napi_null:
                    req.answer("null", httpCode, headers)
                  of napi_string:
                    req.answer(resp.getStr, httpCode, headers)
                  of napi_number:
                    req.answer($resp.getInt, httpCode, headers)
                  of napi_boolean:
                    req.answer($resp.getBool, httpCode, headers)
                  of napi_object:
                    let stringRepr = $napiCall("JSON.stringify", [resp]).getStr
                    try:
                      let json = parseJson(stringRepr)
                      req.answerJson(json, httpCode, headers)
                    except JsonParsingError:
                      req.answer(stringRepr, httpCode, headers)
                  else:
                    discard
                else:
                  # Object is just JSON
                  let stringRepr = $napiCall("JSON.stringify", [response]).getStr
                  try:
                    let json = parseJson(stringRepr)
                    req.answerJson(json)
                  except JsonParsingError:
                    req.answer(stringRepr)
              else:
                discard
      if reqResponded:
        break


elif exportPython:
  import ./server
  import nimpy

  template handlePythonRequest*(self: server.Server, req: Request, urlPath: string) =
    var reqResponded = false
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
          if @["MIDDLEWARE"] != route.httpMethod:
            reqResponded = true
          var request = initHttpRequest(req.path.get(), $req.httpMethod.get(), req.headers.get(), req.body.get())
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
                if not route.purePath.endsWith("/") and not fileName.startsWith("/"):
                  route.purePath & "/" & fileName
                else:
                  route.purePath & fileName
              splitted = file.split(".")
              ext = splitted[^1]
            if fileExists(file):
              if extensions.len != 0 or ext in extensions or splitted.len == 1:
                await req.answerFile(file)
          else:
            let
              queryFromUrl = block:
                let val = split(req.path.get(), "?")
                if len(val) >= 2:
                  val[1]
                else:
                  ""
              query = parseQuery(queryFromUrl)
            var
              # Declare RouteData
              routeData = handleRoute(route.path)
              # Declare Python Object (for function params)
              pyFuncParams: PyObject
              pyNone: PyObject
              # Declare JsonNode (for length of keyword arguments)
              keywordArguments: JsonNode
            # Unpack route path params
            let founded_regexp_matches = urlPath.findAll(route.pattern)
            var
              # handle callback data
              variables = newSeq[string]()
              argcount = route.handler.getAttr("__code__").getAttr("co_argcount")
              varnames = route.handler.getAttr("__code__").getAttr("co_varnames")
              pDefaults = route.handler.getAttr("__defaults__")
            # Create Python Object
            pyValueToNim(privateRawPyObj(pDefaults), keywordArguments)
            let annotations = newAnnotations(route.handler.getAttr("__annotations__"))
            # Extract function arguments from Python
            for i in 0..<(argcount.to(int) - keywordArguments.len):
              variables.add(varnames[i].to(string))
            let
              # Match function parameters with annotations (or without)
              handlerParams = newHandlerParams(variables, annotations)
              # Load path params into function parameters
              funcParams = getRouteParams(routeData, founded_regexp_matches, urlPath, handlerParams, req.body.get())
              none = newPyNone()
            none.pyValueToNim(pyNone)
            # Add queries to function parameters
            for param in handlerParams:
              if not (pyNone != callMethod(funcParams, "get", param.name)) and not (param.paramType in @["HttpRequest", "WebSocket"]):
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
              pyFuncParams[handlerParams.getParamName("HttpRequest")] = request
            let arr = py.list(callMethod(funcParams, "keys")).to(JsonNode)
            # Detect and create classes for request models
            for param in arr:
              let paramType = handlerParams.getParamType(param.getStr)
              if paramType in requestModelsHidden:
                var requestModel = requestModelsHidden[paramType].pyClass
                # Create Python class instance
                let pyClassInstance = requestModel.from_dict(requestModel, pyFuncParams[param])
                pyFuncParams[param] = pyClassInstance
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
              of "JsonResponseObj":
                let resp = response.to(JsonResponseObj)
                req.answerJson(resp.data, HttpCode(resp.statusCode), resp.headers.toHttpHeaders)
              of "HtmlResponseObj":
                let resp = response.to(HtmlResponseObj)
                req.answerHtml(resp.data, HttpCode(resp.statusCode), resp.headers.toHttpHeaders)
              of "FileResponseObj":
                let resp = response.to(FileResponseObj)
                await req.answerFile(resp.filename, HttpCode(resp.statusCode), resp.asAttachment)
              else:
                req.answer($response)
