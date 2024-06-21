import
  ../src/happyx


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
