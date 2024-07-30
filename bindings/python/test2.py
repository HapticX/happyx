from happyx import new_server, register_route_param_type


app = new_server("127.0.0.1", 5000)


@register_route_param_type("my_unique_id", r"\d+")
class MyUniqueIdentifier:
    def __init__(self, data: str):
        self.identifier = int(data)


@register_route_param_type("asd", r"\d\w\d")
def parse_asd(data: str) -> tuple:
    return int(data[0]), data[1], int(data[2])


@app.get("/registered/{data}/{asd:asd}")
def handle(data: MyUniqueIdentifier, asd):
    print(data.identifier)
    print(asd)
    return {'response': data.identifier, 'asd': asd}


@register_route_param_type("user", r"\d+")
class User:
    def __init__(self, data: str):
        identifier = int(data)
        self.load_from_db()
    
    def load_from_db(self):
        ...


@app.get("/user/id{user}")
def get_user(user: User):
    ...


@app.get("/")
def index():
    return ""


@app.get("/user/{id}")
def get_user(id: int):
    return f"{id}"


@app.post("/user")
def create_user():
    return ""


app.start()
