package com.hapticx.response;

import com.google.gson.Gson;
import com.hapticx.data.HttpHeader;
import com.hapticx.data.HttpHeaders;

import java.util.List;

public class JsonResponse extends BaseResponse {
    private void addHeaders() {
        this.headers.add(new HttpHeader("Content-Type", "application/json; charset=utf-8"));
    }

    public JsonResponse(String data, int httpCode, HttpHeaders headers) {
        super(data, httpCode, headers);
        this.addHeaders();
    }

    public JsonResponse(String data, int httpCode, List<HttpHeader> headers) {
        super(data, httpCode, headers);
        this.addHeaders();
    }

    public JsonResponse(String data, int httpCode) {
        super(data, httpCode);
        this.addHeaders();
    }

    public JsonResponse(String data) {
        super(data);
        this.addHeaders();
    }
}
