## # Decorators 🔌
## 
## Provides convenient wrapper to create route decorators
## 
## > It can be used for plugins also
## 
## ## Decorator Usage Example ✨
## 
## 
## .. code-block:: nim
##    serve ...:
##      @AuthBasic
##      get "/":
##        # password and username takes from header "Authorization"
##        # Authorization: Bearer BASE64
##        echo username
##        echo password
## 
## 
## ## Own decorators
## 
## 
## .. code-block:: nim
##    proc myDecorator(httpMethods: seq[string], routePath: string, statementList: NimNode) =
##      statementList.insert(0, newCall("echo", newLit"My own decorator"))
##    # Register decorator
##    static:
##      regDecorator("MyDecorator", myDecorator)
##    # Use it
##    serve ...:
##      @MyDecorator
##      get "/":
## 
import
  ./decorators/base,
  ../core/constants

export base


when enableDefaultDecorators:
  import
    ./decorators/builtin/auth,
    ./decorators/builtin/cached,
    ./decorators/builtin/rate_limit,
    ./decorators/builtin/user_agent
  
  export
    auth,
    cached,
    rate_limit,
    user_agent
