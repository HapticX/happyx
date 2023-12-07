package com.hapticx.response;

import com.hapticx.data.HttpHeader;
import com.hapticx.data.HttpHeaders;

import java.util.List;

import static java.nio.charset.StandardCharsets.ISO_8859_1;
import static java.nio.charset.StandardCharsets.UTF_8;

public class BaseResponse {
    protected final String data;
    protected final int httpCode;
    protected final HttpHeaders headers;

    public BaseResponse(String data, int httpCode, HttpHeaders headers) {
        this.data = data;
        this.httpCode = httpCode;
        this.headers = headers;
    }

    public BaseResponse(String data, int httpCode, List<HttpHeader> headers) {
        this.data = data;
        this.httpCode = httpCode;
        this.headers = new HttpHeaders();
        this.headers.addAll(headers);
    }

    public BaseResponse(String data, int httpCode) {
        this.data = data;
        this.httpCode = httpCode;
        this.headers = new HttpHeaders();
    }

    public BaseResponse(String data) {
        this.data = data;
        this.httpCode = 200;
        this.headers = new HttpHeaders();
    }

    public HttpHeaders getHeaders() {
        return headers;
    }

    public int getHttpCode() {
        return httpCode;
    }

    public String getData() {
        return data;
    }

    @Override
    public String toString() {
        return "BaseResponse{" +
                "data='" + data + '\'' +
                ", httpCode=" + httpCode +
                ", headers=" + headers +
                '}';
    }
}
