package com.hapticx.callback;

import com.hapticx.data.HttpRequest;

public interface RequestCallback {
    Object onRequest(HttpRequest req);
}
