import
  ../src/happyx


regCORS:
  credentials: true
  origins: "https://www.google.com"  # You can send request from this address
  methods: ["GET", "POST", "PUT"]
  headers: "*"


serve("127.0.0.1", 5000):
  "/":
    return "Hello, world!"

  @AuthBasic  # username and password will in your code.
  get "/user{id}":
    echo username
    echo password
    return {"response": {
      "id": id,
      "username": username,
      "password": password
    }}
