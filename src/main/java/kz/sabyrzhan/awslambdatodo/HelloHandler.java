package kz.sabyrzhan.awslambdatodo;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;

import java.util.Map;

public class HelloHandler implements RequestHandler<Map<String, String>, String> {
    @Override
    public String handleRequest(Map<String, String> stringStringMap, Context context) {
        return "Hello World";
    }
}
