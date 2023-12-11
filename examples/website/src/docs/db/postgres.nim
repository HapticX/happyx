# Import HappyX
import
  ../../../../../src/happyx,
  ../../ui/[colors, code, play_states, translations],
  ../../components/[
    code_block_guide, code_block, tip
  ]


component Postgres:
  `template`:
    tDiv(class = "flex flex-col px-8 py-2 backdrop-blur-sm xl:h-fit gap-4"):
      tH1: {translate"PostgreSQL 📦"}

      case currentLanguage.val
      of "Nim":
        tP: {translate"This article discusses the interaction of HappyX and PostgreSQL using Norm library."}
      of "Python":
        tP: {translate"This article discusses the interaction of HappyX and PostgreSQL using psycopg2 library."}

      tP: {translate"First, you need to install the library to work with it"}

      CodeBlockGuide(@[
        ("Nim", "shell", "nimble install -y norm", cstring"nim_postgres_install", newPlayResult()),
        ("Python", "shell", "pip install psycopg2", cstring"py_postgres_install", newPlayResult()),
        # ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
        # ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
      ])

      if currentLanguage == "Nim":
        
        Tip(ttInfo):
          tP: {translate"Norm requires ``--deepcopy:on``, so you'll have to compile your project with this flag:"}
          CodeBlock("shell", "nim c -r --deepcopy:on file.nim", "nim_postgre_1")

        tP: {translate"First, let's look at an example in which Norm is imported and a model is created for a table in a database."}

        CodeBlock("nim", nimPostgreSql1, "nim_postgre_1")
        
        tP: {translate"The code below shows the connection to PostgreSQL"}
      elif currentLanguage == "Python":

        tP: {translate"The code below shows connecting to PostgreSQL and creating a model for a table in the database."}

      CodeBlockGuide(@[
        ("Nim", "nim", nimPostgreSql2, cstring"nim_postgre_2", newPlayResult()),
        ("Python", "python", pyPostgreSql1, cstring"py_postgre_1", newPlayResult()),
        # ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
        # ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
      ])

      tP: {translate"Now let's write methods for working with the pseudo-API. Let's start by creating a user:"}

      CodeBlockGuide(@[
        ("Nim", "nim", nimPostgreSql3, cstring"nim_postgre_3", newPlayResult()),
        ("Python", "python", pyPostgreSql2, cstring"py_postgre_2", newPlayResult()),
        # ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
        # ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
      ])

      tP: {translate"Now let's write a method to get a user by his ID:"}

      CodeBlockGuide(@[
        ("Nim", "nim", nimPostgreSql4, cstring"nim_postgre_4", newPlayResult()),
        ("Python", "python", pyPostgreSql3, cstring"py_postgre_3", newPlayResult()),
        # ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
        # ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
      ])

      tP: {translate"Finally, let's add a method to get all users"}

      CodeBlockGuide(@[
        ("Nim", "nim", nimPostgreSql5, cstring"nim_postgre_5", newPlayResult()),
        ("Python", "python", pyPostgreSql4, cstring"py_postgre_4", newPlayResult()),
        # ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
        # ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
      ])

      tP: {translate"Let's take a look at the full code:"}

      CodeBlockGuide(@[
        ("Nim", "nim", nimPostgreSql, cstring"nim_postgre_full", newPlayResult()),
        ("Python", "python", pyPostgreSql, cstring"py_postgre_full", newPlayResult()),
        # ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
        # ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
      ])

      tP: {translate"Now you know the basics of working with PostgreSQL in HappyX."}

      tP:
        case currentLanguage.val
        of "Nim":
          tA(href = "https://norm.nim.town"):
            {translate"Norm documentation"}
        of "Python":
          tA(href = "https://www.psycopg.org/docs/usage.html"):
            {translate"psycopg2 documentation"}
