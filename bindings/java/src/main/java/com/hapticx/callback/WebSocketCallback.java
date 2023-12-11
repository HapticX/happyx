package com.hapticx.callback;

import com.hapticx.data.WSConnection;

public interface WebSocketCallback {
    void onReceive(WSConnection sock);
}
