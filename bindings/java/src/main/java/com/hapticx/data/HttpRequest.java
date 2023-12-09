package com.hapticx.data;


import com.hapticx.util.LibLoader;

public class HttpRequest {
    static {
        LibLoader.load("happyx");
    }

    private final String id;
    private final String method;
    private final String body;
    private final String path;
    private final String hostname;

    private final Queries queries;
    private final HttpHeaders headers;
    private final PathParam params;

    private native void answer(String id, Object data);

    public HttpRequest(String id, String method, String body,
                       String path, String hostname, Queries queries,
                       HttpHeaders headers, PathParam params
    ) {
        this.id = id;
        this.method = method;
        this.body = body;
        this.path = path;
        this.hostname = hostname;
        this.queries = queries;
        this.headers = headers;
        this.params = params;
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

    public String getHostname() {
        return hostname;
    }

    public Queries getQueries() {
        return queries;
    }

    public HttpHeaders getHeaders() {
        return headers;
    }

    public PathParam getParams() {
        return params;
    }

    public void answer(Object data) {
        answer(id, data);
    }
}
