import happyx.happyx as happyx
from collections import defaultdict


__version__ = "2.2.3"

HttpRequest = happyx.HttpRequest
Response = happyx.Response
FileResponse = happyx.FileResponse
HtmlResponse = happyx.HtmlResponse
JsonResponse = happyx.JsonResponse
new_server = happyx.new_server
reg_CORS = happyx.reg_CORS


class RequestModelBaseMeta(type):
    def __new__(meta, name, bases, dct):
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
