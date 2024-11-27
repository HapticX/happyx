import
  ../src/happyx


model MyModel:
  username: string
  data: string = "Hi! :)" # you can use default value 🍍
  age: int


serve("127.0.0.1", 5000):
  # myModel is param name
  # MyModel is model name
  "/[myModel:MyModel]":
    echo myModel.username, ", ", myModel.age, ", ", myModel.data
    return { "response": {
      "username": myModel.username,
      "age": myModel.age,
      "data": myModel.data
    }}

  "/immutable/[myModel:MyModel]":
    echo myModel.username, ", ", myModel.age, ", ", myModel.data
    myModel.age += 10
    return { "response": {
      "username": myModel.username,
      "age": myModel.age,
      "data": myModel.data
    }}
  
  get "/get":
    echo query  # StringTableRef
    echo urlPath  # string
    echo query?id  # string
    return query?id
