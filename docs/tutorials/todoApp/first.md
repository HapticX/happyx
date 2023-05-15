# TODO App ✨

## Part 1


### Create project

In this tutorial series we create todo single page application.

We should to create project at first.

```bash
hpx create
```

### `main.nim`

Let's open main script. We'll see

```nim
import
  happyx,
  components/[hello_world]


appRoutes("app"):
  "/":
    component HelloWorld
```

---

This documentation was generated with [`HapDoc`](https://github.com/HapticX/hapdoc)

