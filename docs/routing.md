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


## (Im)mutable Params ⚙

Route path params is immutable by default. You can change it by add `[m]` after type:

- `$arg:type[m]=val`
- `$arg:type[m]`
- `$arg[m]`
- `$arg?[m]`


## pathParams Macro 🛠

macro `pathParams` provides path params assignment. With it you can assign path params and use it in routes.

Example syntax:
```nim
pathParams:
  # means that `arg` of type `int` is optional mutable param with default value `5`
  arg? int[m] = 5
  # means that `arg1` of type `string` is optional mutable param with default value `"Hello"`
  arg1[m] = "Hello"
  # means that `arg2` of type `string` is immutable regex param
  arg2 re"\d+u"
  # means that `arg3` of type `float` is mutable param
  arg3 float[m]
  # means that `arg4` of type `int` is optional mutable param with default value `10`
  arg4:
    type int
    mutable
    optional
    default = 10
```

---

This documentation was generated with [`HapDoc`](https://github.com/HapticX/hapdoc)
