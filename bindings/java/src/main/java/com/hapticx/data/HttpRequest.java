package com.hapticx.data;


public class HttpRequest {
    private final int serverId;
    private final String method;
    private final String body;
    private final String path;

    private final Queries queries;
    private final HttpHeaders headers;
    private final PathParam pathParam;

    public HttpRequest(int serverId, String method, String body,
                       String path, Queries queries, HttpHeaders headers,
                       PathParam pathParam
    ) {
        this.serverId = serverId;
        this.method = method;
        this.body = body;
        this.path = path;
        this.queries = queries;
        this.headers = headers;
        this.pathParam = pathParam;
    }

    public String getMethod() {
        return this.method;
    }

    public String getPath() {
        return this.path;
    }

    public String getBody() {
        return this.body;
    }

    public Queries getQueries() {
        return queries;
    }

    public HttpHeaders getHeaders() {
        return headers;
    }

    public PathParam getPathParam() {
        return pathParam;
    }
}
