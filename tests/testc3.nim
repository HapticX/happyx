import ../src/happyx


pathParams:
  id int
  count? int = 1



serve("127.0.0.1", 5000):
  get "/":
    """"""
  
  get "/user/$id":
    id
  
  post "/user":
    """"""
  
  get "/some":
    # echo req.path.get()
    # echo req.pathWithQueries.get()
    urlPath
  
  notfound:
    """method not allowed"""
