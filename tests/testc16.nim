import
  ../src/happyx


var x = generate_password("secret")

echo "secret".check_password(x)
echo "secret1".check_password(x)


serve "127.0.0.1", 5000:
  get "/":
    echo inCookies
    cookies.add(setCookie("bestFramework", "HappyX!", secure = true, httpOnly = true))
    return "Hello, world!"
  get "/setStatusCode":
    statusCode = 404
    return "Hello, world!"
