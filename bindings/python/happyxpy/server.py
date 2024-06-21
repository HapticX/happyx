import asyncio
from typing import Callable, Any, List
from re import match

from .constants import SWAGGER_HTML_SOURCE, REDOC_HTML_SOURCE

import happyxpy.happyx as happyx


Callback = Callable[[Any], Any]


class Server:
    """
    Provides HTTP Server made with HappyX
    """

    __all__ = [
      '__init__',
      '__str__',
      'get', 'post', 'put', 'delete',
      'purge', 'unlink', 'link', 'copy',
      'head', 'options', 'websocket',
      'notfound', 'middleware',
      'mount', 'static',
      'start',
      'host', 'port', 'path'
    ]

    def __init__(
            self,
            host: str = '127.0.0.1',
            port: int = 5000,
            path: str = None,
            openapi: bool = True,
            redoc_url: str = "/redoc",
            swagger_url: str = "/swagger"
    ):
        """
        Creates a new server

        Keyword arguments:
        host {str} -- server address (default '127.0.0.1')
        port {int} -- server port (default 5000)
        path {str} -- server path. Uses for `mount` and `__div__` methods (default None)
        openapi {bool} -- enable/disable openapi endpoints (OpenAPI, ReDoc and Swagger)
        redoc_url {str} -- ReDoc endpoint (default "/redoc")
        swagger_url {str} -- Swagger endpoint (default "/swagger")
        """
        self.host = host
        self.port = port
        self._server = happyx.new_server(host, port)
        self.path = path
        # OpenAPI docs
        self._swagger_url = swagger_url
        self._redoc_url = redoc_url
        self._openapi_data = {
          "openapi": "3.1.0",
          "swagger": "2.0",
          "info": {"title": "HappyX OpenAPI Docs", "version": "1.0.0"},
          "paths": {},
          "components": {
            "schemas": {},
            "parameters": {},
            "responses": {},
            "securitySchemas": {},
            "headers": {},
            "links": {},
            "callbacks": {},
            "pathItems": {},
            "examples": {},
            "requestBodies": {}
          }
        }
        if openapi:
            self._openapi_endpoints()
    
    def __str__(self) -> str:
        """
        Returns server's string representation
        """
        return f'Server<{self._server}> at http://{self.host}:{self.port}'
    
    def __del__(self) -> None:
        """
        Deletes current server
        """
        if hasattr(self, '_server'):
            happyx.delete_server(self._server)
    
    def __eq__(self, other) -> bool:
        """
        Returns True on current and other server IDs is same
        """
        if not isinstance(other, Server):
            return False
        return self._server == other._server
    
    def __div__(self, other) -> None:
        """
        Mounts other server into current server
        """
        self.mount(other)

    def _add_route_data(self, route: str, cb: Callback, methods: List[str] = None) -> None:
        """
        Registers route data into openapi docs
        """
        if methods is None:
            return
        pathData = {
            "description": cb.__doc__,
            "parameters": [],
            "requestBody": {},
            "responses": {}
        }
        # fetch parameters
        arg_count = cb.__code__.co_argcount
        annotations = cb.__annotations__
        defaults = cb.__defaults__ if cb.__defaults__ is not None else tuple()
        for i in range(arg_count):
            arg_name = cb.__code__.co_varnames[i]
            arg_val = None
            arg_type = None
            required = True
            in_query = not match(r"(\$" + str(arg_name) + r"|\{" + str(arg_name) + r"\})", route)
            # keyword argument
            if arg_count - i <= len(defaults):
                arg_val = defaults[arg_count - i - 1]
                required = False
            # annotations
            if arg_name in annotations:
                arg_type = annotations[arg_name]
            # not annotated but keyword argument
            if arg_type is None and arg_val is not None:
                arg_type = type(arg_val)
            # check if arg_type is request or anything else
            if arg_type.__name__ == "HttpRequest":
                continue
            # add param to pathData
            paramData = {
                "name": arg_name,
                "required": required,
                "in": "query" if in_query else "path",
                "schema": {}
            }
            if arg_type is not None:
                if arg_type is str:
                    paramData["schema"]["type"] = "string"
                elif arg_type is float:
                    paramData["schema"]["type"] = "number"
                    paramData["schema"]["format"] = "double"
                elif arg_type is int:
                    paramData["schema"]["type"] = "number"
                    paramData["schema"]["format"] = "int64"
                elif arg_type is bool:
                    paramData["schema"]["type"] = "boolean"
                elif arg_type is list:
                    paramData["schema"]["type"] = "array"
                    paramData["schema"]["items"] = {}
            pathData["parameters"].append(paramData)
        # Write to openapi data
        if route in self._openapi_data["paths"]:
            # if exists
            for m in methods:
                self._openapi_data["paths"][route][m] = pathData
            return
        # create a new route and write to it
        self._openapi_data["paths"][route] = {}
        for m in methods:
            self._openapi_data["paths"][route][m] = pathData

    def _openapi_endpoints(self):
        # Create /docs/openapi.json endpoint
        def _openapi_endpoint():
            return self._openapi_data

        def _redoc_endpoint():
            return happyx.HtmlResponse(
                REDOC_HTML_SOURCE % f"{happyx.server_path(self._server)}/docs/openapi.json"
            )
        
        def _swagger_endpoint():
            return happyx.HtmlResponse(
                SWAGGER_HTML_SOURCE % f"{happyx.server_path(self._server)}/docs/openapi.json"
            )
        
        # Bind swagger URL if available
        if isinstance(self._swagger_url, str):
            happyx.get_server(self._server, self._swagger_url, _swagger_endpoint)
        # Bind openapi URL if available
        if isinstance(self._redoc_url, str):
            happyx.get_server(self._server, self._redoc_url, _redoc_endpoint)
        happyx.get_server(self._server, "/docs/openapi.json", _openapi_endpoint)

    def _add_task(self, task) -> None:
        self.tasks.append(task)
    
    def start(self) -> None:
        """
        Starts server listening
        """
        happyx.start_server_by_id(self._server)
    
    def route(self, route: str, methods: List[str] = None) -> Callable[[Callback], Any]:
        """
        Creates a new route
        """
        if methods is None:
            methods = []
        def _wrapper(cb: Callback):
            self._add_route_data(route, cb, methods)
            happyx.route_server(self._server, route, methods, cb)
        return _wrapper
    
    def get(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new GET route
        """
        def _wrapper(cb: Callback):
            self._add_route_data(route, cb, ["get"])
            happyx.get_server(self._server, route, cb)
        return _wrapper
    
    def post(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new POST route
        """
        def _wrapper(cb: Callback):
            self._add_route_data(route, cb, ["post"])
            happyx.post_server(self._server, route, cb)
        return _wrapper

    def put(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new PUT route
        """
        def _wrapper(cb: Callback):
            self._add_route_data(route, cb, ["put"])
            happyx.put_server(self._server, route, cb)
        return _wrapper

    def purge(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new PURGE route
        """
        def _wrapper(cb: Callback):
            self._add_route_data(route, cb, ["purge"])
            happyx.purge_server(self._server, route, cb)
        return _wrapper

    def copy(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new COPY route
        """
        def _wrapper(cb: Callback):
            self._add_route_data(route, cb, ["copy"])
            happyx.copy_server(self._server, route, cb)
        return _wrapper

    def head(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new HEAD route
        """
        def _wrapper(cb: Callback):
            self._add_route_data(route, cb, ["head"])
            happyx.head_server(self._server, route, cb)
        return _wrapper

    def delete(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new DELETE route
        """
        def _wrapper(cb: Callback):
            self._add_route_data(route, cb, ["delete"])
            happyx.delete_server(self._server, route, cb)
        return _wrapper

    def options(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new OPTIONS route
        """
        def _wrapper(cb: Callback):
            self._add_route_data(route, cb, ["options"])
            happyx.options_server(self._server, route, cb)
        return _wrapper

    def link(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new LINK route
        """
        def _wrapper(cb: Callback):
            self._add_route_data(route, cb, ["link"])
            happyx.link_server(self._server, route, cb)
        return _wrapper

    def unlink(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new UNLINK route
        """
        def _wrapper(cb: Callback):
            self._add_route_data(route, cb, ["unlink"])
            happyx.unlink_server(self._server, route, cb)
        return _wrapper

    def websocket(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new WEBSOCKET route
        """
        def _wrapper(cb: Callback):
            happyx.websocket_server(self._server, route, cb)
        return _wrapper

    def middleware(self, cb: Callback) -> None:
        """
        Creates a new MIDDLEWARE route for all routes
        """
        happyx.middleware_server(self._server, cb)

    def notfound(self, cb: Callback) -> None:
        """
        Creates a new NOTFOUND route for this server object
        """
        happyx.notfound_server(self._server, cb)

    def mount(self, route: str = None, other = None) -> None:
        """
        Creates a new mount for other server

        Keyword arguments:
        route {str} -- mounting path (default taken from other Server)
        other {Server} -- other server that should be mounted (default is None)
        """
        if not isinstance(other, Server):
            raise ValueError('mounting canceled! Other is not Server')
        if route is None:
            if other.path is None:
                raise ValueError('mounting canceled! route is None')
            route = other.path
        happyx.mount_server(self._server, route, other._server)
    
    def static(self, route: str, directory: str, extensions: List[str] = None) -> None:
        """
        Creates a new static route
        """
        if extensions is None:
            extensions = []
        happyx.static_server(self._server, route, directory, extensions)
