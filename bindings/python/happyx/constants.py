REDOC_HTML_SOURCE = """<html>
<head>
  <title>HappyX x ReDoc</title>
  <meta charset="utf-8">
  <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Montserrat:300,400,700|Roboto:300,400,700">
  <style>
    body {
      margin: 0;
      padding: 0;
    }
  </style>
</head><body>
  <redoc spec-url="%s"></redoc>
  <script src="https://cdn.jsdelivr.net/npm/redoc@next/bundles/redoc.standalone.js"></script>
</body></html>
"""

SWAGGER_HTML_SOURCE = """<html>
<head>
  <title>HappyX x Swagger</title>
  <meta charset="utf-8">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@3/swagger-ui.css">
  <link rel="shortcut icon">
</head><body>
  <div id="docs"></div>
  <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@3/swagger-ui-bundle.js"></script>
  <script>
    const ui = SwaggerUIBundle({
      url: '%s',
      oauth2RedirectUrl: window.location.origin + '/docs/swagger/oauth2-redirect',
      dom_id: '#docs',
      presets: [
        SwaggerUIBundle.presets.apis,
        SwaggerUIBundle.SwaggerUIStandalonePreset
      ],
      layout: "BaseLayout",
      deepLinking: true
    })
  </script>
</body></html>
"""
