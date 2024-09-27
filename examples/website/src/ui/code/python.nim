const
  pythonHelloWorldExample* = """from happyx import Server

# Create application
app = Server('127.0.0.1', 5000)


# GET method
@app.get('/')
def hello_world():
    # Respond plaintext
    return 'Hello, world!'


# start our app
app.start()
"""
  pythonProject* = """project/
├─ main.py
├─ README.md
├─ .gitignore
"""
  pythonSsrCalc* = """@app.get('/calc/{left}/{op}/{right}')
def calculate(left: float, right: float, op: str):
    if op == "+":
        return left + right
    elif op == "-":
        return left - right
    elif op == "/":
        return left / right
    elif op == "*":
        return left * right
    else:
        return Response("failure", status_code=404)
"""
  pythonPathParamsSsr* = """app = Server()

@app.get('/user/id{user_id}')
def handle(user_id: int):
    # Here we can use user_id
    print(user_id)
    return {'response': user_id}
"""
  pySsrAdvancedHelloWorld* = """from happyx import Server, JsonResponse, Response


app = Server('127.0.0.1', 5000)


@app.get('/statusCode')
def test_only_status_code():
    return JsonResponse(
        {"response": "This page not working because I want it :p"},
        status_code = 404
    )


@app.get('/customHeaders')
def test_only_headers():
    return Response(
        0,
        headers = {
          "Backend-Server": "HappyX"
        }
    )


@app.get('/customCookies')
def test_only_cookies():
    return Response(
        0,
        headers = {
          "Set-Cookie": "bestFramework=HappyX!"
        }
    )


@app.get('/')
def test_all():
    return Response(
        1,
        headers = {
          "Reason": "Auth Failed",
          "Set-Cookie": "happyx-auth-reason=HappyX"
        },
        status_code = 401
    )


app.start()
"""
  pySsrAdditionalRoutes* = """from happyx import Server, HttpRequest


app = Server("127.0.0.1", 5000)

app.static("/path/to/directory", './directory')


@app.notfound()
def on_not_found():
    return "Oops, seems like this route is not available"


@app.middleware()
def on_not_found(req: HttpRequest):
    print(req.path())


app.start()
"""
  pyMongoDb1* = """from happyx import Server
from pymongo import MongoClient
from datetime import datetime


app = Server('127.0.0.1', 5000)
mongo_client = MongoClient()
db = mongo_client["happyx_test"]
users_coll = db["users"]
"""
  pyMongoDb2* = """
@app.post("/user/new")
def create_user():
    users_count = users_coll.count_documents({})
    result = users_coll.insert_one({
        "countId": users_count,
        "addedTime": datetime.utcnow()
    })
    return {"response": "success" if result.acknowledged else "failure"}
"""
  pyMongoDb3* = """
@app.get("/user/id{user_id:int}")
def read_user(user_id: int):
    user = users_coll.find_one({"countId": user_id})
    if user is None:
        return {"response": "failure"}
    else:
        return {
            "countId": user["countId"],
            "addedTime": user["addedTime"]
        }
"""
  pyMongoDb4* = """
@app.get("/users")
def read_users():
    users = users_coll.find()
    response = []
    for user in users:
        response.append({
            "countId": user["countId"],
            "addedTime": user["addedTime"]
        })
    return response


app.start()
"""
  pyMongoDb* = """from happyx import Server
from pymongo import MongoClient
from datetime import datetime


app = Server('127.0.0.1', 5000)
mongo_client = MongoClient()
db = mongo_client["happyx_test"]
users_coll = db["users"]


@app.post("/user/new")
def create_user():
    users_count = users_coll.count_documents({})
    result = users_coll.insert_one({
        "countId": users_count,
        "addedTime": datetime.utcnow()
    })
    return {"response": "success" if result.acknowledged else "failure"}


@app.get("/user/id{user_id:int}")
def read_user(user_id: int):
    user = users_coll.find_one({"countId": user_id})
    if user is None:
        return {"response": "failure"}
    else:
        return {
            "countId": user["countId"],
            "addedTime": user["addedTime"]
        }


@app.get("/users")
def read_users():
    users = users_coll.find()
    response = []
    for user in users:
        response.append({
            "countId": user["countId"],
            "addedTime": user["addedTime"]
        })
    return response


app.start()
"""
  pySqlalchemy* = """from happyx import Server
from sqlalchemy import create_engine, Column, Integer, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime


Base = declarative_base()
engine = create_engine("sqlite:///users.db")
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base.metadata.create_all(bind=engine)


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    lastLogin = Column(DateTime)


app = Server('127.0.0.1', 5000)


@app.post("/user/new")
def create_user():
    user = User(lastLogin=datetime.now())
    db = SessionLocal()
    db.add(user)
    db.commit()
    db.refresh(user)
    db.close()
    return {"response": "success"}


@app.get("/user/id{user_id:int}")
def read_user(user_id: int):
    db = SessionLocal()
    user = db.query(User).filter(User.id == user_id).first()
    db.close()
    if user is None:
        return {"response": "failure"}
    return {"id": user.id, "lastLogin": user.lastLogin}


@app.get("/users")
def read_users():
    db = SessionLocal()
    users = db.query(User).all()
    db.close()
    response = []
    for user in users:
        response.append({"id": user.id, "lastLogin": user.lastLogin})
    return response


app.start()
"""
  pySqlalchemy1* = """from happyx import Server
from sqlalchemy import create_engine, Column, Integer, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime


Base = declarative_base()
engine = create_engine("sqlite:///users.db")
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base.metadata.create_all(bind=engine)


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    lastLogin = Column(DateTime)
"""
  pySqlalchemy2* = """
app = Server('127.0.0.1', 5000)


@app.post("/user/new")
def create_user():
    user = User(lastLogin=datetime.now())
    db = SessionLocal()
    db.add(user)
    db.commit()
    db.refresh(user)
    db.close()
    return {"response": "success"}
"""
  pySqlalchemy3* = """
@app.get("/user/id{user_id:int}")
def read_user(user_id: int):
    db = SessionLocal()
    user = db.query(User).filter(User.id == user_id).first()
    db.close()
    if user is None:
        return {"response": "failure"}
    return {"id": user.id, "lastLogin": user.lastLogin}
"""
  pySqlalchemy4* = """
@app.get("/users")
def read_users():
    db = SessionLocal()
    users = db.query(User).all()
    db.close()
    response = []
    for user in users:
        response.append({"id": user.id, "lastLogin": user.lastLogin})
    return response


app.start()
"""
  pyPostgreSql* = """import psycopg2
from happyx import Server
from datetime import datetime

# Connect to postgresql
connection = psycopg2.connect(
    user="postgres",
    password="123456",
    host="127.0.0.1",
    port="5432",
    database="test"
)

with connection.cursor() as cursor:
    cursor.execute(
        '''
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            lastLogin TIMESTAMP
        )
        '''
    )
connection.commit()

app = Server('127.0.0.1', 5000)

@app.post("/user/new")
def create_user():
    with connection.cursor() as cursor:
        cursor.execute(
            '''
            INSERT INTO users (lastLogin)
            VALUES (%s)
            RETURNING id, lastLogin
            ''',
            (datetime.now(),)
        )
        user = cursor.fetchone()
    connection.commit()
    return {"response": "success", "id": user[0], "lastLogin": user[1]}

@app.get("/user/id{user_id:int}")
def read_user(user_id: int):
    with connection.cursor() as cursor:
        cursor.execute(
            '''
            SELECT id, lastLogin FROM users
            WHERE id = %s
            ''',
            (user_id,)
        )
        user = cursor.fetchone()
    if user is None:
        return {"response": "failure"}
    return {"id": user[0], "lastLogin": user[1]}

@app.get("/users")
def read_users():
    with connection.cursor() as cursor:
        cursor.execute(
            '''
            SELECT id, lastLogin FROM users
            '''
        )
        users = cursor.fetchall()
    response = [{"id": user[0], "lastLogin": user[1]} for user in users]
    return response

app.start()
"""
  pyPostgreSql1* = """import psycopg2
from happyx import Server
from datetime import datetime

# Connect to postgresql
connection = psycopg2.connect(
    user="postgres",
    password="123456",
    host="127.0.0.1",
    port="5432",
    database="test"
)

with connection.cursor() as cursor:
    cursor.execute(
        '''
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            lastLogin TIMESTAMP
        )
        '''
    )
connection.commit()
"""
  pyPostgreSql2* = """app = Server('127.0.0.1', 5000)

@app.post("/user/new")
def create_user():
    with connection.cursor() as cursor:
        cursor.execute(
            '''
            INSERT INTO users (lastLogin)
            VALUES (%s)
            RETURNING id, lastLogin
            ''',
            (datetime.now(),)
        )
        user = cursor.fetchone()
    connection.commit()
    return {"response": "success", "id": user[0], "lastLogin": user[1]}"""
  pyPostgreSql3* = """@app.get("/user/id{user_id:int}")
def read_user(user_id: int):
    with connection.cursor() as cursor:
        cursor.execute(
            '''
            SELECT id, lastLogin FROM users
            WHERE id = %s
            ''',
            (user_id,)
        )
        user = cursor.fetchone()
    if user is None:
        return {"response": "failure"}
    return {"id": user[0], "lastLogin": user[1]}"""
  pyPostgreSql4* = """@app.get("/users")
def read_users():
    with connection.cursor() as cursor:
        cursor.execute(
            '''
            SELECT id, lastLogin FROM users
            '''
        )
        users = cursor.fetchall()
    response = [{"id": user[0], "lastLogin": user[1]} for user in users]
    return response

app.start()"""
  pyMounting* = """from happyx import Server

app = Server()
profile = Server()

app.mount('/profile', profile)


@profile.get('/')
def get_profile():
  return 'Hello from /profile/'


@profile.get('/{id}')
def get_profile_by_id(id: int):
  return f'Hello, user {id}! Route is /profile/{id}'


@profile.get('/settings')
def get_profile_by_id(id: int):
  return f'Hello from /profile/settings'


app.start()
"""
