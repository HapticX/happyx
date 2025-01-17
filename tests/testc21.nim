import
  ../src/happyx


regCORS:
  methods: "*"
  origins: "*"
  headers: "*"
  credentials: true


serve "127.0.0.1", 5000:
  get "/":
    ""
  get "/user/$id":
    id
  post "/user":
    ""
  
  # Server-sent events
  # https://github.com/HapticX/happyx/discussions/365
  sse "/sse":
    while true:
      let now = now().utc.format("ddd, d MMM yyyy HH:mm:ss")
      await req.sseSend("time", now)
      await sleepAsync(2500)

  notfound:
    "method not allowed"
