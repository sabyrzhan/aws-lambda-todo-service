package kz.sabyrzhan.awslambdatodo.model;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class Todo {
    private long timestamp;
    private String data;
    private int userId;
}
