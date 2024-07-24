from happyx import (
    FileResponse, HtmlResponse, JsonResponse, HttpRequest, WebSocket,
    Response, HappyX, reg_cors, RequestModelBase, __version__
)


app = HappyX()
user = HappyX()
sub_user = HappyX()

print(app)

app.static("/static", './')
app.mount("/user", user)
user.mount("/sub", sub_user)

print(__version__)


class User(RequestModelBase):
    first_name: str
    identifier: int


class Message(RequestModelBase):
    from_user: User
    text: str


class Auth(RequestModelBase):
    username: str
    password: str


@app.websocket('/ws')
async def handle_websocket_connection(ws: WebSocket):
    if ws.id() == 2:
        ws.send_text("failure")
        ws.close()
    print(ws.state())
    print(ws.id())
    if ws.state() == 'open':  # connect/open/close/mismatch_protocol/handshake_error/error
        print(ws.receive_text())
        ws.send_json({"hello": "world"})
    else:
        print(ws.state())


@user.get("/id{userId?}")
async def hello_from_user(userId: int):
    return f"Hello, {userId} user!"


@user.route('/', ['get', 'post'])
async def handle():
    return "You'll see it only on GET or POST"


@user.post("/messages[u]")
async def get_messages(req: HttpRequest, u: User):
    print(u)
    print(u.first_name, u.identifier)
    return u.to_dict()


@sub_user.get("/")
async def test():
    return "hi"


reg_cors(
    allow_methods=["*"],
    allow_origins="https://www.google.com"
)


@app.get("/")
async def read_root(req: HttpRequest) -> dict:
    print(req)
    print(req.path())
    return {"Hello": "World"}


@app.get("/calc/$i/$j")
async def read_root(i: int, j: int):
    print("i + j is", i + j)
    return JsonResponse(
        {"hello": "world"},
        status_code = 404
    )


@app.get("/hello_world")
async def read_root(req: HttpRequest, required: bool, optional = 5):
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


@app.notfound
async def on_not_found():
    return HtmlResponse(
        "<h1>Oops! Not found!</h1>",
        headers = {
            'Accept-Language': 'ja'
        }
    )


@app.middleware
async def on_not_found(req: HttpRequest):
    # print(f"Middleware handled path at [{req.http_method()}]:", req.path())
    # print(f"Middleware detect these headers: {req.headers()}")
    # print(f"Middleware detect this body: {req.body()}")
    pass


app.run()
