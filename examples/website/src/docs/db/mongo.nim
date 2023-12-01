# Import HappyX
import
  ../../../../../src/happyx,
  ../../ui/[colors, code, play_states, translations],
  ../../components/[
    code_block_guide, code_block
  ]


component MongoDB:
  `template`:
    tDiv(class = "flex flex-col px-8 py-2 backdrop-blur-sm xl:h-fit gap-4"):
      tH1: {translate"MongoDB 🍃"}

      tP: {translate"In this article, we will look at the interaction with MongoDB on the server side."}

      tP: {translate"First, you need to install MongoDB and the library to work with it"}

      component CodeBlockGuide(@[
        ("Nim", "nim", "nimble install anonimongo@#head", cstring"nim_mongo_db_install", newPlayResult()),
        ("Python", "python", "pip install pymongo", cstring"py_mongo_db_install", newPlayResult()),
        # ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
        # ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
      ])

      tP: {translate"The code below shows the connection to MongoDB"}

      component CodeBlockGuide(@[
        ("Nim", "nim", nimSsrMongoDb1, cstring"nim_mongo_db_1", newPlayResult()),
        ("Python", "python", pyMongoDb1, cstring"py_mongo_db_1", newPlayResult()),
        # ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
        # ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
      ])

      tP: {translate"Now let's write methods for working with the pseudo-API. Let's start by creating a user:"}

      component CodeBlockGuide(@[
        ("Nim", "nim", nimSsrMongoDb2, cstring"nim_mongo_db_2", newPlayResult()),
        ("Python", "python", pyMongoDb2, cstring"py_mongo_db_2", newPlayResult()),
        # ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
        # ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
      ])

      tP: {translate"Now let's write a method to get a user by his ID:"}

      component CodeBlockGuide(@[
        ("Nim", "nim", nimSsrMongoDb3, cstring"nim_mongo_db_3", newPlayResult()),
        ("Python", "python", pyMongoDb3, cstring"py_mongo_db_3", newPlayResult()),
        # ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
        # ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
      ])

      tP: {translate"Finally, let's add a method to get all users"}

      component CodeBlockGuide(@[
        ("Nim", "nim", nimSsrMongoDb4, cstring"nim_mongo_db_4", newPlayResult()),
        ("Python", "python", pyMongoDb4, cstring"py_mongo_db_4", newPlayResult()),
        # ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
        # ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
      ])

      tP: {translate"Let's take a look at the full code:"}

      component CodeBlockGuide(@[
        ("Nim", "nim", nimSsrMongoDb, cstring"nim_mongo_db", newPlayResult()),
        ("Python", "python", pyMongoDb, cstring"py_mongo_db", newPlayResult()),
        # ("JavaScript", "javascript", jsHelloWorldExample, cstring"js_import", newPlayResult()),
        # ("TypeScript", "typescript", tsHelloWorldExample, cstring"ts_import", newPlayResult()),
      ])

      tP: {translate"Now you know the basics of working with MongoDB in HappyX."}

      tP:
        case currentLanguage.val
        of "Nim":
          tA(href = "https://github.com/mashingan/anonimongo"):
            {translate"anonimongo documentation"}
        of "Python":
          tA(href = "https://pymongo.readthedocs.io/"):
            {translate"pymongo documentation"}
