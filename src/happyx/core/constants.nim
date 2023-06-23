## # Constants ✨
## > Provides HappyX constants

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

when defined(js):
  const
    enableOldRenderer* = defined(oldRenderer) or defined(happyxOldRenrerer)
