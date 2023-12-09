package com.hapticx.data;

import com.hapticx.util.LibLoader;

import java.lang.reflect.Field;
import java.util.Arrays;
import java.util.List;

public class BaseRequestModel {
    static {
        LibLoader.load("happyx");
    }

    private static native void registerRequestModel(String modelName, List<Field> fields);

    public BaseRequestModel() {

    }

    public List<Field> getFieldList() {
        return Arrays.asList(this.getClass().getFields());
    }

    public static void register(BaseRequestModel model) {
        registerRequestModel(model.getClass().getName(), model.getFieldList());
    }
}
