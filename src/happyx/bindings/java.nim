import
  jnim,
  jnim/private/[jni_wrapper, jni_export],
  ../ssr/[server],
  ../core/[exceptions],
  nimja,
  sugar,
  tables,
  strutils,
  macros


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
        newIdentDefs(ident"jClass", ident"JClass"),
      ]
    )
    p.body = s.body
    p.body.insert(0, newCall("setupForeignThreadGc"))
    for i in 1..s.params.len-1:
      p.params.add(s.params[i])
    p.addPragma(ident"cdecl")
    p.addPragma(ident"exportc")
    p.addPragma(ident"dynlib")
    result.add(p)
  echo result.toStrLit


var
  servers = newTable[jint, Server]()
  uniqueServerId: jint = 0


nativeMethods com.hapticx~Server:
  proc createServer(host: jstring, port: jint): jint =
    initJNI(env)
    inc uniqueServerId
    servers[uniqueServerId] = newServer($host, port.int)
    return uniqueServerId
  
  proc callFromNative(callback: jobject): jint =
    initJNI(env)
    echo "Hello from Nim!"
    var
      jClass = env.GetObjectClass(env, callback)
      methodId = env.GetMethodId(env, jClass, "call", "()V")
    echo "so, call java callback!"
    env.CallVoidMethod(env, callback, methodId)
    echo "called!"

  
  proc startServer(serverId: jint) =
    {.gcsafe.}:
      var self = servers[serverId]
      if not self.parent.isNil():
        raise newException(
          HpxAppRouteDefect, fmt"Server that you start shouldn't be mounted!"
        )
    serve self.address, self.port:
      discard


# proc Java_com_hapticx_Server_runNim*(env: JNIEnvPtr, x: JClass) {. cdecl, exportc, dynlib .} =
#   system.setupForeignThreadGc()
#   echo "Printing from JNI..."


# proc Java_com_hapticx_HappyX_sum*(env: JNIEnvPtr, x: JClass, a, b: jint): jint {. cdecl, exportc, dynlib .} =
#   system.setupForeignThreadGc()
#   return a + b


# proc Java_com_hapticx_HappyX_intToString*(env: JNIEnvPtr, x: JClass, a: jint): jstring {. cdecl, exportc, dynlib .} =
#   system.setupForeignThreadGc()
  
#   return env.NewStringUTF(env, cstring($a))


# proc Java_com_hapticx_HappyX_forCycle*(env: JNIEnvPtr, x: JClass, a: jint): jint {. cdecl, exportc, dynlib .} =
#   system.setupForeignThreadGc()

#   var a = a.int32
  
#   for i in 0..0x7fffffff:
#     a += 1
  
#   return a
