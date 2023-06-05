# SSR ✨

HappyX provides powerful tools to create server side applications.

## CORS ⚙
To setting Cross-Origin Resource Sharing (CORS) you should use `regCORS` macro

```nim
regCORS:
  credentials: true
  origins: "domen.com"  # or "*"
  methods: ["GET", "POST"]  # or "*"
  headers: "*"  # or ["Header-Name", "Other-Header"]
```


## Request Models 🔨

In RestAPI you can send JSON body. To work with it you should use `model` macro

### Model Declaring ✨
```nim
model User:
  login: string
  password: string
  optionalData: string = "something"
```

### Model Usage 🎈
```nim
serve(...):
  var id = 0
  
  "/path[u:User]":
    echo u.login
    inc id
    return {"response": {
      "id": id
    }}
```

---

This documentation was generated with [`HapDoc`](https://github.com/HapticX/hapdoc)
