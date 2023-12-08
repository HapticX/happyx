# Import HappyX
import
  ../../../../../src/happyx,
  ../../ui/[colors, code, play_states, translations],
  ../../components/[
    code_block_guide, code_block, tip
  ]


component SQLite:
  `template`:
    tDiv(class = "flex flex-col px-8 py-2 backdrop-blur-sm xl:h-fit gap-4"):
      tH1: {translate"SQLite 📦"}

      case currentLanguage.val
      of "Nim":
        tP: {translate"This article discusses the interaction of Happy and SQLite using Norm library."}
      of "Python":
        tP: {translate"This article discusses the interaction of Happy and SQLite using sqlalchemy library."}

      tP: {translate"First, you need to install the library to work with it"}

      component CodeBlockGuide(@[
        ("Nim", "shell", "nimble install -y norm", cstring"nim_sqlite_install", newPlayResult()),
        ("Python", "shell", "pip install sqlalchemy", cstring"py_sqlite_install", newPlayResult()),
        # ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
        # ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
      ])

      if currentLanguage == "Nim":
        
        component Tip:
          tP: {translate"Norm requires ``--deepcopy:on``, so you'll have to compile your project with this flag:"}
          component CodeBlock("shell", "nim c -r --deepcopy:on file.nim", "nim_sqlite_1")

        tP: {translate"First, let's look at an example in which Norm is imported and a model is created for a table in a database."}

        component CodeBlock("nim", nimSsrNormSqlite1, "nim_sqlite_1")
        
        tP: {translate"The code below shows the connection to SQLite"}
      elif currentLanguage == "Python":

        tP: {translate"The code below shows connecting to SQLite and creating a model for a table in the database."}

      component CodeBlockGuide(@[
        ("Nim", "nim", nimSsrNormSqlite2, cstring"nim_sqlite_2", newPlayResult()),
        ("Python", "python", pySqlalchemy1, cstring"py_sqlite_1", newPlayResult()),
        # ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
        # ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
      ])

      tP: {translate"Now let's write methods for working with the pseudo-API. Let's start by creating a user:"}

      component CodeBlockGuide(@[
        ("Nim", "nim", nimSsrNormSqlite3, cstring"nim_sqlite_3", newPlayResult()),
        ("Python", "python", pySqlalchemy2, cstring"py_sqlite_2", newPlayResult()),
        # ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
        # ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
      ])

      tP: {translate"Now let's write a method to get a user by his ID:"}

      component CodeBlockGuide(@[
        ("Nim", "nim", nimSsrNormSqlite4, cstring"nim_sqlite_4", newPlayResult()),
        ("Python", "python", pySqlalchemy3, cstring"py_sqlite_3", newPlayResult()),
        # ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
        # ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
      ])

      tP: {translate"Finally, let's add a method to get all users"}

      component CodeBlockGuide(@[
        ("Nim", "nim", nimSsrNormSqlite5, cstring"nim_sqlite_5", newPlayResult()),
        ("Python", "python", pySqlalchemy4, cstring"py_sqlite_4", newPlayResult()),
        # ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
        # ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
      ])

      tP: {translate"Let's take a look at the full code:"}

      component CodeBlockGuide(@[
        ("Nim", "nim", nimSsrNormSqlite, cstring"nim_sqlite_full", newPlayResult()),
        ("Python", "python", pySqlalchemy, cstring"py_sqlite_full", newPlayResult()),
        # ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
        # ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
      ])

      tP: {translate"Now you know the basics of working with SQLite in HappyX."}

      tP:
        case currentLanguage.val
        of "Nim":
          tA(href = "https://norm.nim.town"):
            {translate"Norm documentation"}
        of "Python":
          tA(href = "https://www.sqlalchemy.org/"):
            {translate"sqlalchemy documentation"}
