from happyx import (
    FileResponse, HtmlResponse, JsonResponse, HttpRequest,
    Response, new_server, reg_cors, RequestModelBase
)
import happyx


app = new_server()
user = new_server()
sub_user = new_server()

app.mount("/user", user)
user.mount("/sub", sub_user)


class Auth(RequestModelBase):
    username: str
    password: str


@user.get("/id{userId?}")
def hello_from_user(userId: int):
    return f"Hello, {userId} user!"


@sub_user.get("/")
def test():
    return "hi"


reg_cors(
    allow_methods=["*"],
    allow_origins="https://www.google.com"
)


@app.get("/")
def read_root(req: HttpRequest) -> dict:
    print(req)
    print(req.path())
    return {"Hello": "World"}


@app.get("/calc/$i/$j")
def read_root(i: int, j: int):
    print("i + j is", i + j)
    return JsonResponse(
        {"hello": "world"},
        status_code = 404
    )


@app.get("/hello_world")
def read_root(req: HttpRequest, required: bool, optional = 5):
    """
    # Hello, world!
    Responds **Hello, world!**
    """
    print(req.path())
    print(required)
    print(optional)
    return JsonResponse(
        {"required": required, "optional": optional},
        status_code = 404
    )


@app.notfound()
def on_not_found():
    return HtmlResponse(
        "<h1>Oops! Not found!</h1>",
        headers = {
            'Accept-Language': 'ja'
        }
    )


@app.middleware()
def on_not_found(req: HttpRequest):
    print(f"Middleware handled path at [{req.http_method()}]:", req.path())
    print(f"Middleware detect these headers: {req.headers()}")
    print(f"Middleware detect this body: {req.body()}")


app.start()
