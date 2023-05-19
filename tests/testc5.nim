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
    req.answerJson({
      "username": myModel.username,
      "age": myModel.age,
      "data": myModel.data
    })
