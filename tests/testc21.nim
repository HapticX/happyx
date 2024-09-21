import
  ../src/happyx


serve "127.0.0.1", 5000:
  get "/":
    ""
  get "/user/$id":
    id
  post "/user":
    ""
  notfound:
    "method not allowed"
