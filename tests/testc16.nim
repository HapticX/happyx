import
  ../src/happyx


var x = generate_password("secret")

echo "secret".check_password(x)
echo "secret1".check_password(x)


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
  get "/arrQuery":
    ## Parses array and simple queries
    return {
      "arr": queryArr~a,
      "val": query~b
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
    apiUsageExamples:
      req: ""
      answer: "Hello, world!"
    echo inCookies
    cookies.add(setCookie("bestFramework", "HappyX!", secure = true, httpOnly = true))
    return "Hello, world!"
  get "/setStatusCode":
    ## Responds "Hello, world!" with 404 HttpCode
    statusCode = 404
    return "Hello, world!"

  post "/post":
    ## Creates a new post
    return "Hello, world!"

  put "/post$id:int":
    ## Edits a post
    return "Hello, world!"
