import
  jnim,
  jnim/private/[jni_wrapper],
  jnim/java/[lang, util],
  ../ssr/session,
  regex,
  json,
  websocketx,
  httpx,
  tables,
  httpcore,
  strutils


type
  JavaMethod* = ref object
    env*: JNIEnvPtr
    class*: JClass
    methodId*: jmethodID
  Route* = ref object
    path*: string
    purePath*: string
    httpMethod*: seq[string]
    pattern*: Regex2
    handler*: JavaMethod
  HandlerParam* = object
    name*, paramType*: string
  RequestModelData* = object
    name*: string
    fields*: seq[tuple[key, val: string]]
  RequestModels* = object
    requestModels*: seq[RequestModelData]
  # Java objects
  Query* = ref object
    key*: string
    value*: string
  Queries* = seq[Query]
  JavaHttpHeader* = ref object
    key*: string
    value*: string
  JavaHttpHeaders* = seq[JavaHttpHeader]
  PathParamKind* = enum
    ppkInt,
    ppkFloat,
    ppkBool,
    ppkString,
    ppkArr,
    ppkObj
  PathParam* = ref object
    name*: string
    case kind*: PathParamKind
    of ppkInt:
      intVal*: jint
    of ppkFloat:
      floatVal*: jfloat
    of ppkBool:
      boolVal*: jboolean
    of ppkString:
      strVal*: jstring
    of ppkArr:
      arrVal*: seq[PathParam]
    of ppkObj:
      objVal*: TableRef[string, PathParam]
  HttpRequest* = ref object
    answered*: bool
    id*: string
    httpMethod*: string
    body*: string
    path*: string
    hostname*: string
    queries*: Queries
    headers*: JavaHttpHeaders
    pathParam*: PathParam
    req*: Request
  WebSocketState* {.pure, size: sizeof(int8).} = enum
    wssConnect,
    wssOpen,
    wssClose,
    wssHandshakeError,
    wssMismatchProtocol,
    wssError
  WebSocket* = object
    id*: string
    data*: string
    ws*: websocketx.WebSocket
    state*: WebSocketState


var
  requestModelsHidden* = RequestModels(requestModels: @[])
  wsClients* = newTable[string, java_types.WebSocket]()
  httpRequests* = newTable[string, HttpRequest]()


proc newWebSocketObj*(ws: websocketx.WebSocket, data: string = ""): java_types.WebSocket =
  let id = genSessionId()
  wsClients[id] = java_types.WebSocket(id: id, ws: ws, data: data, state: wssOpen)
  wsClients[id]


const
  HttpRequestClass* = "com/hapticx/data/HttpRequest"
  WSConnectionClass* = "com/hapticx/data/WSConnection"
  PathParamClass* = "com/hapticx/data/PathParam"
  PathParamsClass* = "com/hapticx/data/PathParams"
  QueryClass* = "com/hapticx/data/Query"
  QueriesClass* = "com/hapticx/data/Queries"
  HttpHeaderClass* = "com/hapticx/data/HttpHeader"
  HttpHeadersClass* = "com/hapticx/data/HttpHeaders"
  BaseResponseClass* = "com/hapticx/response/BaseResponse"


jclass com.hapticx.data.HttpHeader as HttpHeaderJVM of Object:
  proc new*(key: string, value: string)
  proc getKey*: string
  proc getValue*: string
  proc toString*: string


jclass com.hapticx.data.PathParam as PathParamJVM of Object:
  proc new*(name: string, val: string)

jclass com.hapticx.data.PathParams as PathParamsJVM of List[PathParamJVM]:
  proc new*

jclass com.hapticx.data.PathParamMap as PathParamMapJVM of HashMap[string, PathParamJVM]:
  proc new*


jclass com.hapticx.data.HttpHeaders as HttpHeadersJVM of ArrayList[HttpHeaderJVM]:
  proc new*
  proc get*(key: string)


jclass com.hapticx.response.BaseResponse* of Object:
  proc new*(data: string, httpCode: jint, httpHeaders: HttpHeadersJVM)
  proc new*(data: string, httpCode: jint)
  proc new*(data: string)
  proc getHeaders*: HttpHeadersJVM
  proc getHttpCode*: jint
  proc getData*: string
  proc toString*: string


jclass com.hapticx.response.HtmlResponse* of BaseResponse:
  proc new*(data: string, httpCode: jint, httpHeaders: HttpHeadersJVM)
  proc new*(data: string, httpCode: jint)
  proc new*(data: string)


jclass com.hapticx.response.FileResponse* of BaseResponse:
  proc new*(data: string, httpCode: jint, httpHeaders: HttpHeadersJVM)
  proc new*(data: string, httpCode: jint)
  proc new*(data: string)


jclass com.hapticx.response.JsonResponse* of BaseResponse:
  proc new*(data: string, httpCode: jint, httpHeaders: HttpHeadersJVM)
  proc new*(data: string, httpCode: jint)
  proc new*(data: string)

jclass java.lang.reflect.AccessibleObject* of Object:
  proc new*


jclass java.lang.Class of Object:
  proc getName*(): string

jclass java.lang.reflect.Field* of AccessibleObject:
  proc getName*(): string
  proc getType*(): Class

jclass com.hapticx.data.BaseRequestModel* of Object:
  proc getFieldList*(): List[Field]



proc initJavaMethod*(env: JNIEnvPtr, class: JClass, methodId: jmethodID): JavaMethod =
  JavaMethod(env: env, class: class, methodId: methodId)


proc initRoute*(path, purePath: string, httpMethod: seq[string], pattern: Regex2, handler: JavaMethod): Route =
  Route(path: path, purePath: purePath, httpMethod: httpMethod, pattern: pattern, handler: handler)


proc initHttpRequest*(httpMethod, body, path, hostname: string,
                      req: Request, queries: Queries = @[],
                      headers: JavaHttpHeaders = @[],
                      pathParam: PathParam = PathParam.default): HttpRequest =
  let id = genSessionId()
  result = HttpRequest(
    httpMethod: httpMethod, body: body, path: path,
    hostname: hostname, id: id, req: req, queries: queries,
    headers: headers, pathParam: pathParam
  )
  httpRequests[id] = result


proc toPathParam*(env: JNIEnvPtr, obj: JsonNode, name: string = ""): PathParam =
  case obj.kind
  of JString:
    return PathParam(name: name, kind: ppkString, strVal: env.NewStringUTF(env, obj.getStr()))
  of JInt:
    return PathParam(name: name, kind: ppkInt, intVal: obj.getInt().jint)
  of JFloat:
    return PathParam(name: name, kind: ppkFloat, floatVal: obj.getFloat().jfloat)
  of JBool:
    return PathParam(name: name, kind: ppkBool, boolVal: if obj.getBool(): JVM_TRUE else: JVM_FALSE)
  of JArray:
    result = PathParam(name: name, kind: ppkArr, arrVal: @[])
    for i in obj:
      result.arrVal.add(env.toPathParam(i, name))
    return result
  of JObject:
    result = PathParam(name: name, kind: ppkObj, objVal: newTable[string, PathParam]())
    for vkey, vval in obj.pairs:
      result.objVal[vkey] = env.toPathParam(vval, vkey)
    return result
  else:
    discard


proc getObjectType*(env: JNIEnvPtr, obj: JVMObject): string =
  let jClass = env.GetObjectClass(env, obj.get())
  let getClassMethod = env.GetMethodId(env, jClass, "getClass", "()Ljava/lang/Class;")
  let classObj = env.CallObjectMethod(env, obj.get(), getClassMethod)
  let classClass = env.GetObjectClass(env, classObj)
  let getNameMethod = env.GetMethodId(env, classClass, "getName", "()Ljava/lang/String;")
  let objName = env.CallObjectMethod(env, classObj, getNameMethod)
  return newJVMObject(objName).toStringRaw


proc toJava*(env: JNIEnvPtr, self: Query): jobject =
  let
    class = env.FindClass(env, QueryClass)
    constructor = env.GetMethodId(
      env, class, "<init>", "(Ljava/lang/String;Ljava/lang/String;)V"
    )
    res = env.NewObject(
      env, class, constructor,
      env.NewStringUTF(env, cstring(self.key)),
      env.NewStringUTF(env, cstring(self.value)),
    )
  return res


proc toJava*(env: JNIEnvPtr, self: Queries): jobject =
  let
    class = env.FindClass(env, QueriesClass)
    constructor = env.GetMethodId(env, class, "<init>", "()V")
    addMethod = env.GetMethodID(env, class, "add", "(Lcom/hapticx/data/Query;)Z")
    res = env.NewObject(env, class, constructor)
  for query in self:
    let jObj = env.toJava(query)
    discard env.CallBooleanMethod(env, res, addMethod, jObj)
  return res


proc toJava*(env: JNIEnvPtr, self: JavaHttpHeader): jobject =
  let
    class = env.FindClass(env, HttpHeaderClass)
    constructor = env.GetMethodId(
      env, class, "<init>", "(Ljava/lang/String;Ljava/lang/String;)V"
    )
    res = env.NewObject(
      env, class, constructor,
      env.NewStringUTF(env, cstring(self.key)),
      env.NewStringUTF(env, cstring(self.value)),
    )
  return res


proc toJava*(env: JNIEnvPtr, self: JavaHttpHeaders): jobject =
  let
    class = env.FindClass(env, HttpHeadersClass)
    constructor = env.GetMethodId(env, class, "<init>", "()V")
    addMethod = env.GetMethodID(env, class, "add", "(Lcom/hapticx/data/HttpHeader;)Z")
    res = env.NewObject(env, class, constructor)
  for header in self:
    let jObj = env.toJava(header)
    discard env.CallBooleanMethod(env, res, addMethod, jObj)
  return res


proc toJava*(env: JNIEnvPtr, self: PathParam): jobject =
  let
    class = env.FindClass(env, PathParamClass)
    constructor = env.GetMethodId(
      env, class, "<init>",
      case self.kind
      of ppkInt:
        cstring"(Ljava/lang/String;I)V"
      of ppkFloat:
        cstring"(Ljava/lang/String;F)V"
      of ppkBool:
        cstring"(Ljava/lang/String;Z)V"
      of ppkString:
        cstring"(Ljava/lang/String;Ljava/lang/String;)V"
      of ppkArr:
        cstring"(Ljava/lang/String;Lcom/hapticx/data/PathParams;)V"
      of ppkObj:
        cstring"(Ljava/lang/String;Lcom/hapticx/data/PathParamMap;)V"
    )
  return case self.kind
    of ppkInt:
      env.NewObject(
        env, class, constructor,
        env.NewStringUTF(env, cstring(self.name)),
        self.intVal,
      )
    of ppkFloat:
      env.NewObject(
        env, class, constructor,
        env.NewStringUTF(env, cstring(self.name)),
        self.floatVal,
      )
    of ppkBool:
      env.NewObject(
        env, class, constructor,
        env.NewStringUTF(env, cstring(self.name)),
        self.boolVal,
      )
    of ppkString:
      env.NewObject(
        env, class, constructor,
        env.NewStringUTF(env, cstring(self.name)),
        self.strVal,
      )
    of ppkArr:
      var list = PathParamsJVM.new
      for i in self.arrVal:
        discard list.add(cast[PathParamJVM](newJVMObject(env.toJava(i))))
      env.NewObject(
        env, class, constructor,
        env.NewStringUTF(env, cstring(self.name)),
        list.get
      )
    of ppkObj:
      var map = PathParamMapJVM.new
      for vkey, vval in self.objVal:
        discard map.put(vkey, cast[PathParamJVM](newJVMObject(env.toJava(vval))))
      env.NewObject(
        env, class, constructor,
        env.NewStringUTF(env, cstring(self.name)),
        map.get
      )


proc toJava*(env: JNIEnvPtr, self: HttpRequest): jobject =
  ## Converts HttpRequest to HttpRequest JavaObject
  let
    class = env.FindClass(env, HttpRequestClass)
    constructor = env.GetMethodId(
      env, class, "<init>",
      "(" &
      "Ljava/lang/String;" &  # HttpRequest id
      "Ljava/lang/String;" &  # HTTP method
      "Ljava/lang/String;" &  # body
      "Ljava/lang/String;" &  # path
      "Ljava/lang/String;" &  # hostname
      "Lcom/hapticx/data/Queries;" &
      "Lcom/hapticx/data/HttpHeaders;" &
      "Lcom/hapticx/data/PathParam;" &
      ")V"
    )
  let
    res = env.NewObject(
      env, class, constructor,
      env.NewStringUTF(env, cstring(self.id)),
      env.NewStringUTF(env, cstring(self.httpMethod)),
      env.NewStringUTF(env, cstring(self.body)),
      env.NewStringUTF(env, cstring(self.path)),
      env.NewStringUTF(env, cstring(self.hostname)),
      env.toJava(self.queries),
      env.toJava(self.headers),
      env.toJava(self.pathParam),
    )
  return res


proc toJava*(env: JNIEnvPtr, self: java_types.WebSocket): jobject =
  ## Converts HttpRequest to HttpRequest JavaObject
  let
    class = env.FindClass(env, WSConnectionClass)
    constructor = env.GetMethodId(
      env, class, "<init>",
      "(Ljava/lang/String;Ljava/lang/String;Lcom/hapticx/data/WSConnection$State;)V"
    )
    stateClass = env.FindClass(env, "com/hapticx/data/WSConnection$State")
    fieldId = env.GetStaticFieldId(
      env, stateClass,
      case self.state
      of wssConnect:
        cstring"CONNECT"
      of wssOpen:
        cstring"OPEN"
      of wssClose:
        cstring"CLOSE"
      of wssHandshakeError:
        cstring"HANDSHAKE_ERROR"
      of wssMismatchProtocol:
        cstring"MISMATCH_PROTOCOL"
      of wssError:
        cstring"ERROR",
      cstring"Lcom/hapticx/data/WSConnection$State;"
    )
    state = env.GetStaticObjectField(env, stateClass, fieldId)
  return env.NewObject(
    env, class, constructor,
    env.NewStringUTF(env, cstring(self.id)),
    env.NewStringUTF(env, cstring(self.data)),
    state
  )


proc toHttpHeaders*(env: JNIEnvPtr, obj: HttpHeadersJVM): HttpHeaders =
  result = newHttpHeaders()
  if env.getObjectType(obj) != "com.hapticx.data.HttpHeaders":
    return result
  
  for e in obj.toSeq:
    result[$e.getKey()] = $e.getValue()


proc hasHttpMethod*(self: Route, httpMethod: string | seq[string] | openarray[string]): bool =
  when httpMethod is string:
    return self.httpMethod.contains(httpMethod)
  else:
    for i in httpMethod:
      if self.httpMethod.contains(i):
        return true
    return false


proc newHandlerParams*(args: openarray[string], annotations: JsonNode): seq[HandlerParam] =
  result = @[]
  for arg in args:
    if annotations.hasKey(arg):
      result.add(HandlerParam(name: arg, paramType: annotations[arg].str))
    else:
      result.add(HandlerParam(name: arg, paramType: "any"))


proc contains*(params: seq[HandlerParam], key: string): bool =
  for param in params:
    if param.name == key:
      return true
  false


proc hasParamType*(params: seq[HandlerParam], key: string): bool =
  for param in params:
    if param.paramType == key:
      return true
  false


proc contains*(self: RequestModels, name: string): bool =
  for m in self.requestModels:
    if m.name == name:
      return true
  false


proc getParamType*(params: seq[HandlerParam], key: string): string =
  for param in params:
    if param.name == key:
      return param.paramType
  ""


proc `[]`*(params: seq[HandlerParam], key: string): string = params.getParamType(key)


proc `[]`*(self: RequestModels, name: string): RequestModelData =
  for m in self.requestModels:
    if m.name == name:
      return m


proc getParamName*(params: seq[HandlerParam], paramType: string): string =
  for param in params:
    if param.paramType.toLower() == paramType.toLower():
      return param.name
  ""
