from happyx import new_server, register_route_param_type


app = new_server("127.0.0.1", 5000)


class MyUniqueIdentifier:
    def __init__(self, data: str):
        self.identifier = int(data)


register_route_param_type("my_unique_id", r"\d+", MyUniqueIdentifier)


@app.get("/registered/{data:my_unique_id}")
def handle(data: MyUniqueIdentifier):
    print(data.identifier)
    return {'response': data.identifier}


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
