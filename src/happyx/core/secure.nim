## # Secure 🔐
## 
##   This module provides security tools
## 
import
  nimcrypto

export
  nimcrypto


using
  source: string
  hash: MDigest[256]


proc generate_password*(source): MDigest[256] =
  sha3_256.digest(source)


proc check_password*(source, hash): bool =
  sha3_256.digest(source) == hash
