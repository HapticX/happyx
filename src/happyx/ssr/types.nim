import
  std/logging,
  std/tables,
  ../spa/renderer,
  ../core/constants

when enableHttpx:
  import
    std/options,
    httpx
  export
    options,
    httpx
elif enableBuiltin:
  import
    std/options,
    ./core
  export
    options,
    core
elif enableHttpBeast:
  import httpbeast, std/asyncnet
  export httpbeast, asyncnet
elif enableMicro:
  import std/asyncnet, microasynchttpserver, std/asynchttpserver
  export asyncnet, microasynchttpserver, asynchttpserver
else:
  import std/asyncnet, std/asynchttpserver
  export asyncnet, asynchttpserver


when enableHttpBeast:
  import websocket
  export websocket
else:
  import websocketx
  export websocketx


when enableDefaultComponents:
  when exportPython or defined(docgen):
    import
      nimpy,
      ../bindings/python_types
    
    pyExportModule(name = "server", doc = """
  HappyX web framework [SSR/SSG Part]
  """)

    type
      Server* = ref object
        address*: string
        port*: int
        routes*: seq[Route]
        path*: string
        parent*: Server
        notFoundCallback*: PyObject
        middlewareCallback*: PyObject
        logger*: Logger
        when enableHttpx or enableBuiltin:
          instance*: Settings
        elif enableHttpBeast:
          instance*: Settings
        elif enableMicro:
          instance*: MicroAsyncHttpServer
        else:
          instance*: AsyncHttpServer
        components*: TableRef[string, BaseComponent]
      ModelBase* = ref object of PyNimObjectExperimental
  elif exportJvm:
    import ../bindings/java_types

    type
      Server* = ref object
        address*: string
        port*: int
        logger*: Logger
        path*: string
        routes*: seq[Route]
        parent*: Server
        title*: string
        when enableHttpx or enableBuiltin:
          instance*: Settings
        elif enableHttpBeast:
          instance*: Settings
        elif enableMicro:
          instance*: MicroAsyncHttpServer
        else:
          instance*: AsyncHttpServer
        components*: TableRef[string, BaseComponent]
      ModelBase* = object of RootObj
  elif defined(napibuild):
    import denim except `%*`
    import../bindings/node_types

    type
      Server* = ref object
        address*: string
        port*: int
        logger*: Logger
        path*: string
        parent*: Server
        routes*: seq[Route]
        title*: string
        environment*: napi_env
        when enableHttpx or enableBuiltin:
          instance*: Settings
        elif enableHttpBeast:
          instance*: Settings
        elif enableMicro:
          instance*: MicroAsyncHttpServer
        else:
          instance*: AsyncHttpServer
        components*: TableRef[string, BaseComponent]
      ModelBase* = object of RootObj
  else:
    type
      Server* = object
        address*: string
        port*: int
        logger*: Logger
        when enableHttpx or enableBuiltin:
          instance*: Settings
        elif enableHttpBeast:
          instance*: Settings
        elif enableMicro:
          instance*: MicroAsyncHttpServer
        else:
          instance*: AsyncHttpServer
        components*: TableRef[string, BaseComponent]
      ModelBase* = object of RootObj
else:
  when exportPython or defined(docgen):
    import
      nimpy,
      ../bindings/python_types
    
    pyExportModule(name = "server", doc = """
  HappyX web framework [SSR/SSG Part]
  """)

    type
      Server* = ref object
        address*: string
        port*: int
        routes*: seq[Route]
        path*: string
        parent*: Server
        notFoundCallback*: PyObject
        middlewareCallback*: PyObject
        logger*: Logger
        when enableHttpx or enableBuiltin:
          instance*: Settings
        elif enableHttpBeast:
          instance*: Settings
        elif enableMicro:
          instance*: MicroAsyncHttpServer
        else:
          instance*: AsyncHttpServer
      ModelBase* = ref object of PyNimObjectExperimental
  elif exportJvm:
    import ../bindings/java_types

    type
      Server* = ref object
        address*: string
        port*: int
        logger*: Logger
        path*: string
        routes*: seq[Route]
        parent*: Server
        title*: string
        when enableHttpx or enableBuiltin:
          instance*: Settings
        elif enableHttpBeast:
          instance*: Settings
        elif enableMicro:
          instance*: MicroAsyncHttpServer
        else:
          instance*: AsyncHttpServer
      ModelBase* = object of RootObj
  elif defined(napibuild):
    import denim except `%*`
    import../bindings/node_types

    type
      Server* = ref object
        address*: string
        port*: int
        logger*: Logger
        path*: string
        parent*: Server
        routes*: seq[Route]
        title*: string
        environment*: napi_env
        when enableHttpx or enableBuiltin:
          instance*: Settings
        elif enableHttpBeast:
          instance*: Settings
        elif enableMicro:
          instance*: MicroAsyncHttpServer
        else:
          instance*: AsyncHttpServer
      ModelBase* = object of RootObj
  else:
    type
      Server* = object
        address*: string
        port*: int
        logger*: Logger
        when enableHttpx or enableBuiltin:
          instance*: Settings
        elif enableHttpBeast:
          instance*: Settings
        elif enableMicro:
          instance*: MicroAsyncHttpServer
        else:
          instance*: AsyncHttpServer
      ModelBase* = object of RootObj
