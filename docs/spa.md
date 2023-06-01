# SPA ✨

> Single page application 🌐

In HappyX you can create single page applications.

## Create Project 🔨

You need run command and follow the instructions
```bash
hpx create
```

## Components ✨

> You can use components to improve your development experience and speed up your productivity ✌

### Component Declaration 👀
```nim
component Message:
  author: string  # Required param
  text: string  # Required param
  fromId: int = 0  # Optional param
  
  `template`:
    tDiv(class = "..."):
      # message author
      p(class = "..."):
        {self.author}
      # message text
      p(class = "..."):
        {self.text}
  `script`:
    # Here you can use real Nim code
    echo self.author
    echo self.text
    echo self.fromId
  
  `style`:
    # Here CSS string
    """
    div {
      background: gray;
      color: pink;
    }
    """
```

### Component Usage 🍍
```nim
"/":
  ...
  component Message(author = "Me", text = "Hello")
```

### Slots ✌
You can declare component slot
```nim
component Comp:
  `template`:
    tDiv(...):
      slot
```

And use your code in slot ✨
```nim
"/":
  ...
  component Comp(...):
    tDiv(...):
      "Slot is here"
  component Comp(...):
    "👀"
```


### `as` In Components 📕
To write PURE JavaScript or Css you should add `as js` and `as css` in `script` and `style`:

```nim
component Comp:
  ...
  `script` as js:
    console.log("Hello from JS")

    function myFunc(a, b, c):
      # Translates into console.log
      echo "Hi"
  
  `style` as css:
    tag tDiv:
      background-color: rgb(100, 200, 255)
      padding: 0 1.px 2.rem 3.em
```

Read more about [JS](https://hapticx.github.io/happyx/js.html) and [CSS](https://hapticx.github.io/happyx/css.html) in Nim

---

This documentation was generated with [`HapDoc`](https://github.com/HapticX/hapdoc)
