package com.hapticx.response;

import com.hapticx.data.HttpHeader;
import com.hapticx.data.HttpHeaders;

import java.util.List;

public class FileResponse extends BaseResponse {
    public FileResponse(String data, int httpCode, HttpHeaders headers) {
        super(data, httpCode, headers);
    }

    public FileResponse(String data, int httpCode, List<HttpHeader> headers) {
        super(data, httpCode, headers);
    }

    public FileResponse(String data, int httpCode) {
        super(data, httpCode);
    }

    public FileResponse(String data) {
        super(data);
    }
}
