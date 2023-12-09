package com.hapticx.data;

import java.util.HashMap;

public class PathParamMap extends HashMap<String, PathParam> {
    @Override
    public String toString() {
        StringBuilder result = new StringBuilder("{");
        for (Entry<String, PathParam> entry: this.entrySet()) {
            result.append("\"");
            result.append(entry.getKey());
            result.append("\": ");
            result.append(entry.getValue().toString());
            result.append(",");
        }
        result.setLength(result.length() - 1);
        result.append("}");
        return result.toString();
    }
}
