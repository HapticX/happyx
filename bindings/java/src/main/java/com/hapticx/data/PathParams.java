package com.hapticx.data;

import java.util.ArrayList;

public class PathParams extends ArrayList<PathParam> {
    public boolean add(PathParam param) {
        return super.add(param);
    }

    public PathParam get(String pathParamName) {
        for (PathParam p : this) {
            if (p.getName().equals(pathParamName)) {
                return p;
            }
        }
        return null;
    }
}
