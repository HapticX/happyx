package com.hapticx.response;

import com.hapticx.data.HttpHeader;
import com.hapticx.data.HttpHeaders;

import java.util.List;

public class HtmlResponse extends BaseResponse {
    private void addHeaders() {
        this.headers.add(new HttpHeader("Content-Type", "text/html; charset=utf-8"));
    }

    public HtmlResponse(String data, int httpCode, HttpHeaders headers) {
        super(data, httpCode, headers);
        this.addHeaders();
    }

    public HtmlResponse(String data, int httpCode, List<HttpHeader> headers) {
        super(data, httpCode, headers);
        this.addHeaders();
    }

    public HtmlResponse(String data, int httpCode) {
        super(data, httpCode);
        this.addHeaders();
    }

    public HtmlResponse(String data) {
        super(data);
        this.addHeaders();
    }
}
