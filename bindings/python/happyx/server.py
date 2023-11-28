from typing import Callable, Any, List

import happyx.happyx as happyx


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
      'start'
    ]

    def __init__(self, host: str = '127.0.0.1', port: int = 5000, path: str = None):
        """
        Creates a new server

        Keyword arguments:
        host {str} -- server address (default '127.0.0.1')
        port {int} -- server port (default 5000)
        path {str} -- server path. Uses for `mount` and `__div__` methods (default None)
        """
        self.host = host
        self.port = port
        self._server = happyx.new_server(host, port)
        self.path = path
    
    def __str__(self) -> str:
        """
        Returns server's string representation
        """
        return f'Server<{self._server}> at http://{self.host}:{self.port}'
    
    def __del__(self) -> None:
        """
        Deletes current server
        """
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
            happyx.route_server(self._server, route, methods, cb)
        return _wrapper
    
    def get(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new GET route
        """
        def _wrapper(cb: Callback):
            happyx.get_server(self._server, route, cb)
        return _wrapper
    
    def post(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new POST route
        """
        def _wrapper(cb: Callback):
            happyx.post_server(self._server, route, cb)
        return _wrapper

    def put(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new PUT route
        """
        def _wrapper(cb: Callback):
            happyx.put_server(self._server, route, cb)
        return _wrapper

    def purge(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new PURGE route
        """
        def _wrapper(cb: Callback):
            happyx.purge_server(self._server, route, cb)
        return _wrapper

    def copy(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new COPY route
        """
        def _wrapper(cb: Callback):
            happyx.copy_server(self._server, route, cb)
        return _wrapper

    def head(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new HEAD route
        """
        def _wrapper(cb: Callback):
            happyx.head_server(self._server, route, cb)
        return _wrapper

    def delete(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new DELETE route
        """
        def _wrapper(cb: Callback):
            happyx.delete_server(self._server, route, cb)
        return _wrapper

    def options(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new OPTIONS route
        """
        def _wrapper(cb: Callback):
            happyx.options_server(self._server, route, cb)
        return _wrapper

    def link(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new LINK route
        """
        def _wrapper(cb: Callback):
            happyx.link_server(self._server, route, cb)
        return _wrapper

    def unlink(self, route: str) -> Callable[[Callback], Any]:
        """
        Creates a new UNLINK route
        """
        def _wrapper(cb: Callback):
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
