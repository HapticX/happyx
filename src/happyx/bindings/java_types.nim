import
  jnim,
  jnim/private/[jni_wrapper],
  jnim/java/[lang, util],
  regex,
  json,
  httpcore,
  strutils


type
  ResponseObj* = object
    data*: string
    statusCode*: int
    headers*: HashMap[string, string]
  FileResponseObj* = object
    filename*: string
    statusCode*: int
    asAttachment*: bool
  JsonResponseObj* = object
    data*: JsonNode
    statusCode*: int
    headers*: HashMap[string, string]
  HtmlResponseObj* = object
    data*: string
    statusCode*: int
    headers*: HashMap[string, string]
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
    ppkString
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
  PathParams* = seq[PathParam]
  HttpRequest* = ref object
    httpMethod*: string
    body*: string
    path*: string
    serverId*: jint
    queries*: Queries
    headers*: JavaHttpHeaders
    pathParams*: PathParams


var requestModelsHidden* = RequestModels(requestModels: @[])


proc initJavaMethod*(env: JNIEnvPtr, class: JClass, methodId: jmethodID): JavaMethod =
  JavaMethod(env: env, class: class, methodId: methodId)


proc initRoute*(path, purePath: string, httpMethod: seq[string], pattern: Regex2, handler: JavaMethod): Route =
  Route(path: path, purePath: purePath, httpMethod: httpMethod, pattern: pattern, handler: handler)


proc initHttpRequest*(httpMethod, body, path: string,
                      serverId: jint, queries: Queries = @[],
                      headers: JavaHttpHeaders = @[],
                      pathParams: PathParams = @[]): HttpRequest =
  HttpRequest(
    httpMethod: httpMethod, body: body, path: path,
    serverId: serverId, queries: queries,
    headers: headers, pathParams: pathParams
  )


proc toJava*(env: JNIEnvPtr, self: Query): jobject =
  let
    class = env.FindClass(env, "com/hapticx/data/Query")
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
    class = env.FindClass(env, "com/hapticx/data/Queries")
    constructor = env.GetMethodId(env, class, "<init>", "()V")
    addMethod = env.GetMethodID(env, class, "add", "(Lcom/hapticx/data/Query;)Z")
    res = env.NewObject(env, class, constructor)
  for query in self:
    let jObj = env.toJava(query)
    discard env.CallBooleanMethod(env, res, addMethod, jObj)
  return res


proc toJava*(env: JNIEnvPtr, self: JavaHttpHeader): jobject =
  let
    class = env.FindClass(env, "com/hapticx/data/HttpHeader")
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
    class = env.FindClass(env, "com/hapticx/data/HttpHeaders")
    constructor = env.GetMethodId(env, class, "<init>", "()V")
    addMethod = env.GetMethodID(env, class, "add", "(Lcom/hapticx/data/HttpHeader;)Z")
    res = env.NewObject(env, class, constructor)
  for header in self:
    let jObj = env.toJava(header)
    discard env.CallBooleanMethod(env, res, addMethod, jObj)
  return res


proc toJava*(env: JNIEnvPtr, self: PathParam): jobject =
  let
    class = env.FindClass(env, "com/hapticx/data/PathParam")
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


proc toJava*(env: JNIEnvPtr, self: PathParams): jobject =
  let
    class = env.FindClass(env, "com/hapticx/data/PathParams")
    constructor = env.GetMethodId(env, class, "<init>", "()V")
    addMethod = env.GetMethodID(env, class, "add", "(Lcom/hapticx/data/PathParam;)Z")
    res = env.NewObject(env, class, constructor)
  for pathParam in self:
    let jObj = env.toJava(pathParam)
    discard env.CallBooleanMethod(env, res, addMethod, jObj)
  return res


proc toJava*(env: JNIEnvPtr, self: HttpRequest): jobject =
  ## Converts HttpRequest to HttpRequest JavaObject
  let
    class = env.FindClass(env, "com/hapticx/data/HttpRequest")
    constructor = env.GetMethodId(
      env, class, "<init>",
      "(ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;Lcom/hapticx/data/Queries;Lcom/hapticx/data/HttpHeaders;Lcom/hapticx/data/PathParams;)V"
    )
  let
    res = env.NewObject(
      env, class, constructor,
      self.serverId,
      env.NewStringUTF(env, cstring(self.httpMethod)),
      env.NewStringUTF(env, cstring(self.body)),
      env.NewStringUTF(env, cstring(self.path)),
      env.toJava(self.queries),
      env.toJava(self.headers),
      env.toJava(self.pathParams),
    )
  return res


proc toHttpHeaders*(obj: HashMap[string, string]): HttpHeaders =
  result = newHttpHeaders()
  for e in obj.entrySet().toSeq():
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
