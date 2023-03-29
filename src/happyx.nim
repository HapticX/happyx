#[
  Provides Happyx main file
]#
when not defined(js):
  import
    happyx/[server]

  export
    server
else:
  import
    happyx/[renderer]
  
  export
    renderer
