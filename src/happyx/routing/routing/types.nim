## Provides base types for routing
import
  ../../core/constants


type
  PathParamObj* = object
    name*: string
    paramType*: string
    defaultValue*: string
    optional*: bool
  RequestModelObj* = object
    name*: string
    typeName*: string
    target*: string  ## JSON/XML/FormData/X-www-formurlencoded
  RouteDataObj* = object
    pathParams*: seq[PathParamObj]
    requestModels*: seq[RequestModelObj]
    purePath*: string
    path*: string


when exportPython:
  import
    nimpy,
    nimpy/py_types,
    regex,
    ../../bindings/python_types
  type
    RouteObject* = PyObject
elif defined(napibuild):
  import
    denim,
    regex,
    ../../bindings/node_types
  type
    RouteObject* = napi_value
elif exportJvm:
  import
    jnim,
    jnim/private/[jni_wrapper],
    jnim/java/[lang, util],
    regex,
    ../../bindings/java_types
  type
    RouteObject* = PathParam
else:
  import
    std/json
  type
    RouteObject* = JsonNode


func newPathParamObj*(name, paramType, defaultValue: string, optional: bool): PathParamObj =
  PathParamObj(name: name, paramType: paramType, defaultValue: defaultValue, optional: optional)

func newRequestModelObj*(name, typeName, target: string): RequestModelObj =
  RequestModelObj(name: name, typeName: typeName, target: target)
