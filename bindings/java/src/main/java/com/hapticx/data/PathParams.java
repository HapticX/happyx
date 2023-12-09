package com.hapticx.data;

import java.util.ArrayList;

public class PathParams extends ArrayList<PathParam> {
    @Override
    public String toString() {
        StringBuilder result = new StringBuilder("[");
        for (int i = 0; i < size(); i++) {
            if (i < size()-1) {
                result.append(get(i).toString()).append(", ");
            }
            else {
                result.append(get(i).toString());
            }
        }
        result.append("]");
        return result.toString();
    }
}
