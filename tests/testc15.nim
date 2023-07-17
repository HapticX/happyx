import
  ../src/happyx


model MyModel:
  x: int = 100


serve "127.0.0.1", 5000:
  post "/[m:MyModel:urlencoded]":
    echo req.body
    echo m.x
