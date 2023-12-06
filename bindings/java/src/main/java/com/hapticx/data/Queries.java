package com.hapticx.data;

import java.util.ArrayList;

public class Queries extends ArrayList<Query> {
    public boolean add(Query val) {
        return super.add(val);
    }

    public Query get(String key) {
        for (Query q : this) {
            if (q.getKey().equals(key)) {
                return q;
            }
        }
        return null;
    }
}
