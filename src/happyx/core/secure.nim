## # Secure 🔐
## 
##   This module provides security tools
## 
import
  ./constants,
  nimcrypto

export
  nimcrypto


using
  source: string
  hash: MDigest[
    when cryptoMethod == "sha256":
      256
    elif cryptoMethod == "sha224":
      224
    elif cryptoMethod == "sha224":
      384
    else:
      512
  ]


proc generate_password*(source): MDigest[
    when cryptoMethod == "sha256":
      256
    elif cryptoMethod == "sha224":
      224
    elif cryptoMethod == "sha224":
      384
    else:
      512
  ] =
  when cryptoMethod == "sha256":
    sha3_256.digest(source)
  elif cryptoMethod == "sha384":
    sha3_384.digest(source)
  elif cryptoMethod == "sha224":
    sha3_224.digest(source)
  else:
    sha3_512.digest(source)


proc check_password*(source, hash): bool =
  when cryptoMethod == "sha256":
    sha3_256.digest(source) == hash
  elif cryptoMethod == "sha384":
    sha3_384.digest(source) == hash
  elif cryptoMethod == "sha224":
    sha3_224.digest(source) == hash
  else:
    sha3_512.digest(source) == hash
