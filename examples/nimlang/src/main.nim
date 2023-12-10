import
  ../../../src/happyx,
  path_params,
  components/[overview, header],
  app_config


appRoutes "app":
  "/":
    tDiv(class = "flex flex-col"):
      component Header
      component Overview
      
  "/blog":
    tDiv(class = "flex flex-col"):
      component Header

  "/features":
    tDiv(class = "flex flex-col"):
      component Header

  "/download":
    tDiv(class = "flex flex-col"):
      component Header

  "/docs":
    tDiv(class = "flex flex-col"):
      component Header

  "/forum":
    tDiv(class = "flex flex-col"):
      component Header

  "/donate":
    tDiv(class = "flex flex-col"):
      component Header

  "/source":
    tDiv(class = "flex flex-col"):
      component Header
