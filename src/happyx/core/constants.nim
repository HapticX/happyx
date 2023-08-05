## # Constants ✨
## > Provides HappyX constants
## 
## | Flag               | Description                                             |
## | :---:              | :---:                                                   |
## | `-d:httpx`         | enables Httpx as alternative HTTP Server                |
## | `-d:beast`         | enables HttpBeast as alternative HTTP Server            |
## | `-d:micro`         | enables MicroAsyncHttpServer as alternative HTTP Server |
## | `-d:translate`     | enables automatic translate for returns                 |
## | `-d:debug`         | enables debug logging                                   |
## | `-d:oldRenderer`   | enables old renderer for SPA                            |
## | `-d:enableUi`      | enables built-in UI components                          |
## | `-d:disableApiDoc` | disables built-in API documentation                     |
## | `-d:cryptoMethod`  | choose crypto method for `generate_password` methods    |
## | `-d:numThreads`    | choose number of threads (httpx/httpbeast)              |
## | `-d:appName`       | choose name of application (SSR/SSG)                    |
## 
import strformat

when not defined(js):
  import terminal


# Configuration via `-d`/`--define`
const
  # Alternative HTTP Servers
  enableHttpx* = defined(httpx) or defined(happyxHttpx) or defined(hpxHttpx)
  enableMicro* = defined(micro) or defined(happyxMicro) or defined(hpxMicro)
  enableHttpBeast* = defined(beast) or defined(happyxBeast) or defined(hpxBeast)
  # Auto translation in routing
  enableAutoTranslate* = defined(translate) or defined(happyxTranslate) or defined(hpxTranslate)
  # Debug mode
  enableDebug* = defined(debug) or defined(happyxDebug) or defined(hpxDebug)
  # Framework features
  enableUi* = defined(enableUi) or defined(happyxEnableUi) or defined(hpxEnableUi)
  enableApiDoc* = not defined(disableApiDoc)
  numThreads* {. intdefine .} = 0
  appName* {.strdefine.} = "HappyX Application"
  cryptoMethod* {.strdefine.} = "sha512"
  httpMethods* = [
    "get", "post", "put", "patch", "link", "options", "head", "delete", "unlink", "purge", "copy"
  ]
  availableCryptoMethods = ["sha224", "sha256", "sha384", "sha512"]
  # Nim version
  nim_1_6_14* = (NimMajor, NimMajor, NimPatch) == (1, 6, 14)
  nim_2_0_0* = (NimMajor, NimMinor, NimPatch) >= (2, 0, 0)


when cryptoMethod notin availableCryptoMethods:
  raise newException(
    ValueError,
    fmt"cryptoMethod is wrong! it's can be {availableCryptoMethods}, but got {cryptoMethod}"
  )


when defined(js):
  const
    enableOldRenderer* = defined(oldRenderer) or defined(happyxOldRenrerer) or defined(hpxOldRenrerer)


when int(enableHttpx) + int(enableMicro) + int(enableHttpBeast) > 1:
  {. error: "You can't use two alternative servers at one time!" .}


when defined(debug):
  when not defined(js):
    styledEcho fgYellow, fmt"Enable auto translate:       {enableAutoTranslate}"
    styledEcho fgYellow, fmt"Enable httpbeast:            {enableHttpBeast}"
    styledEcho fgYellow, fmt"Enable httpx:                {enableHttpx}"
    styledEcho fgYellow, fmt"Enable MicroAsyncHttpServer: {enableMicro}"
  else:
    static:
      echo fmt"Enable auto translate:       {enableAutoTranslate}"
      echo fmt"Enable httpbeast:            {enableHttpBeast}"
      echo fmt"Enable httpx:                {enableHttpx}"
      echo fmt"Enable MicroAsyncHttpServer: {enableMicro}"
