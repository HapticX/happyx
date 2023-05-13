# Routing ✨

> HappyX provides powerful routing system for both parts (`SSG` and `SPA`) 💡

## Path Params 🍍

Every route has typed `path params` 🙂

Here is example syntax of route 💡
```nim
"/user{id:int}"
```

This route will match any text like this:

- `/user1`
- `/user100`
- `/user1293`

And you can use `id` as immutable declared variable 🔥

```nim
"/user{id:int}":
  echo id
```


## Typing 👮

> Every `path param` is typed 💡

Routes `"/user{id:int}"` and `"/user{id:word}"` is different routes that matches different variables.

In case of `{id:int}` variable is integer.
In case of `{id:word}` variable is string.

Here is list of all available types:

- `int`: matches any integer
- `float`: matches any float
- `bool`: matches any boolean (y, n, yes, no, true, false, 1, 0, on, off)
- `word`: matches any word as string
- `string`: matches any string excludes `'/'` chars
- `path`: matches any string includes `'/'` chars
- `regex`: matches any regex pattern as string (as example `{var:/[a-z][0-9]+/}`)

---

This documentation was generated with [`HapDoc`](https://github.com/HapticX/hapdoc)
