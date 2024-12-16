import
  std/asyncdispatch,
  ../src/happyx,
  jwt


var x = generate_password("secret")

echo "secret".check_password(x)
echo "secret1".check_password(x)


model TestModel:
  username: string
  password: string


model TestModel1:
  username: string
  password: string


model User:
  id: int


model Message:
  text: string
  user: User


model Generics{JSON}[T]:
  field1: T


mount Profile:
  get "/":
    ## Profile main page
    return "Hello, world!"
  
  get "/settings":
    ## Profile settings
    return "Hello, world"
  
  post "/settings":
    ## Update profile settings
    return "Hello, world!"


serve "127.0.0.1", 5000:
  mount "/profile" -> Profile
  "/some":
    ## Hello, world
    return "Hi"
  get "/calculate/$left:float/$operator:string/$right?:float":
    ## Some
    echo left
    echo right
    return fmt"{left + right}"
  get "/auth[model:TestModel:json]":
    ## User authorization
    return "Hello, world!"
  get "/arrQuery":
    ## Parses array and simple queries
    return {
      "arr": queryArr?a,
      "val": query?b
    }
  ws "/Hello":
    discard
  get "/":
    ## Set bestFramework to **"HappyX!"** in cookies
    ## 
    ## ```nim
    ## echo "Hello, world!"
    ## ```
    ## 
    ## Responds "Hello, world!"
    echo inCookies
    outCookies.add(setCookie("bestFramework", "HappyX!", secure = true, httpOnly = true))
    return "Hello, world!"
  get "/setStatusCode":
    ## Responds "Hello, world!" with 404 HttpCode
    statusCode = 404
    if true:
      if true:
        for i in 0..1:
          if true:
            when true:
              statusCode = 400
              return 1
    return "Hello, world!"
  
  get "/headers":
    outHeaders["Test"] = 10
    outHeaders["HappyXHeader"] = "Hello"
    return "Hello, world!"

  post "/post":
    ## Creates a new post
    return "Hello, world!"

  put "/post/$id:int":
    ## Edits a post
    return "Hello, world!"
  
  @Cached  # Expires in 60 seconds by default
  get "/cached/{i:int}":
    await sleepAsync(1000)
    if true:
      if (query?test) == "hello":
        return 100
    echo query?one
    return i
  
  @Cached(120)  # Expires in 60 seconds by default
  get "/cached/{x}":
    await sleepAsync(1000)
    if query.hasKey("key"):
      return query["key"]
    await sleepAsync(1000)
    return x

  @AuthBasic
  post "/test/basic-auth":
    echo username  # from @AuthBasic
    echo password  # from @AuthBasic
    return "Hello, {username}!"

  # You should install jwt library (https://github.com/yglukhov/nim-jwt)
  # to use these decorators
  # Authorization: JWT_TOKEN
  @AuthJWT(token)
  post "/test/jwt":
    if token.hasKey("name"):
      return "Hello, " & token["name"].node.str
    return "who are you???"

  # Authorization: Bearer JWT_TOKEN
  @AuthBearerJWT(token)
  post "/test/jwt-bearer":
    if token.hasKey("name"):
      return "Hello, " & token["name"].node.str
    return "who are you???"
