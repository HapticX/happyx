import
  ../src/happyx


var x = generate_password("secret")

echo "secret".check_password(x)
echo "secret1".check_password(x)


serve "127.0.0.1", 5000:
  middleware:
    echo req.headers
    echo req.headers["connection"]
    echo req.headers["upgrade"]
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
    ## Set bestFramework to "HappyX!" in cookies
    ## 
    ## Responds "Hello, world!"
    echo inCookies
    cookies.add(setCookie("bestFramework", "HappyX!", secure = true, httpOnly = true))
    return "Hello, world!"
  get "/setStatusCode":
    ## Responds "Hello, world!" with 404 HttpCode
    statusCode = 404
    return "Hello, world!"
