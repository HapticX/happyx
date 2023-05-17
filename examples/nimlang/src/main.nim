import
  happyx,
  path_params,
  components/[overview, header],
  app_config


appRoutes("app"):
  "/":
    tDiv(class = "flex flex-column"):
      component Header
      component Overview
      
  "/blog":
    tDiv(class = "flex flex-column"):
      component Header

  "/features":
    tDiv(class = "flex flex-column"):
      component Header

  "/download":
    tDiv(class = "flex flex-column"):
      component Header

  "/docs":
    tDiv(class = "flex flex-column"):
      component Header

  "/forum":
    tDiv(class = "flex flex-column"):
      component Header

  "/donate":
    tDiv(class = "flex flex-column"):
      component Header

  "/source":
    tDiv(class = "flex flex-column"):
      component Header
