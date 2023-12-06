package com.hapticx.data;

import java.util.ArrayList;

public class HttpHeaders extends ArrayList<HttpHeader> {
    public boolean add(HttpHeader val) {
        return super.add(val);
    }

    public HttpHeader get(String key) {
        for (HttpHeader h : this) {
            if (h.getKey().equals(key)) {
                return h;
            }
        }
        return null;
    }
}
