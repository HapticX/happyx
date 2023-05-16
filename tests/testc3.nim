import ../src/happyx


pathParams:
  id int
  count? int = 1


serve("127.0.0.1", 5000):
  var counter = 10

  get "/user/<id>":
    "User {id}"
  
  get "/add/<count>":
    counter += count
    "Now counter = {counter}"
  
  post "/":
    "/"
  
  patch "/asdasd":
    "asdasd"
  
  "/any":
    "asdasdasdasdasd"
