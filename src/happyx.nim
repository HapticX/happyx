## # HappyX
## 
## Main file
## 
when not defined(js):
  import
    happyx/ssg/[server]

  export
    server

import
  happyx/spa/[renderer, state],
  nimja

export
  renderer,
  state,
  nimja
