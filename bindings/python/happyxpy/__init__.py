from collections import defaultdict
from enum import IntEnum

from .server import Server, happyx

try:
    from jinja2 import Template
except ImportError:
    pass


__version__ = happyx.happyx_version()

__all__ = [
    'Server',
    'RequestModelBase',
    'reg_cors',
    'HttpRequest',
    'FileResponse',
    'HtmlResponse',
    'JsonResponse',
    'TemplateResponse',
    'setup_jinja2'
]


# Http Request data
HttpRequest = happyx.HttpRequest
# Response types
Response = happyx.Response
FileResponse = happyx.FileResponse
HtmlResponse = happyx.HtmlResponse
JsonResponse = happyx.JsonResponse
# Web Sockets
WebSocket = happyx.WebSocket
# Main functions
register_route_param_type = happyx.register_route_param_type


__jinja2_templates_directory = './'


def setup_jinja2(directory: str = './') -> None:
    """
    Specifies jinja2 template directory
    """
    __jinja2_templates_directory = directory


def TemplateResponse(
        template_name: str,
        status_code: int = 200,
        headers: dict = None
) -> happyx.HtmlResponseObj:
    """
    Creates a new HtmlResponse that renders from Jinja2 template
    """
    if headers is None:
        headers = {}
    data = ''
    with open(f'{directory}{template_name}', 'r', encoding='utf-8') as f:
        data = f.read()
    rendered = Template(**kwargs).render()
    return HtmlResponse(data, status_code=status_code, headers=headers)


class RequestModelBaseMeta(type):
    """
    RequestModel Base Meta class
    """
    def __new__(meta, name, bases, dct):
        """
        Get all annotations from created class and tells HappyX about request model
        """
        current_class = type.__new__(meta, name, bases, dct)
        if name == 'RequestModelBase':
          return current_class
        fields = []
        if '__annotations__' in dct:
          for key in dct['__annotations__'].keys():
            fields.append((key, dct['__annotations__'][key].__name__))
        happyx.register_request_model_data(happyx.RequestModelData(name, current_class, fields))
        return current_class


class RequestModelBase(object, metaclass=RequestModelBaseMeta):
    """
    Root class to working with request models in Python
    """
    __metaclass__ = RequestModelBaseMeta

    @staticmethod
    def from_dict(cls, dct: dict) -> 'RequestModelBase':
        """
        Creates a new RequestModelBase from dictionary
        """
        current_class = cls()
        for key in dct.keys():
            setattr(current_class, key, dct[key])
        return current_class

    def to_dict(self) -> dict:
        """
        Converts RequestModel to Python dictionary
        """
        return self.__dict__
    
    def __str__(self) -> str:
        """
        Returns string representation
        """
        return "User(" + ", ".join([
            f'{key}={repr(self.__dict__[key])}' for key in self.__dict__.keys()
        ]) + ') at <0x{:0>15x}>'.format(self.__hash__())


def reg_cors(
      allow_methods: list[str] | str | None = None,
      allow_headers: list[str] | str | None = None,
      allow_origins: list[str] | str | None = None,
      credentials: bool = True
) -> None:
    """
    Setup Cross-Origin Resource Sharing
    """
    # Detect allow methods
    if allow_methods is None:
        allow_methods = ""
    elif isinstance(allow_methods, list):
        allow_methods = ",".join(allow_methods)
    # Detect allow headers
    if allow_headers is None:
        allow_headers = ""
    elif isinstance(allow_headers, list):
        allow_headers = ",".join(allow_headers)
    # Detect allow origins
    if allow_origins is None:
        allow_origins = ""
    elif isinstance(allow_origins, list):
        allow_origins = ",".join(allow_origins)
    happyx.reg_CORS(allow_origins, allow_methods, allow_headers, credentials)
