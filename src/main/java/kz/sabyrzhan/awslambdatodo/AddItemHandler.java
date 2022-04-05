package kz.sabyrzhan.awslambdatodo;

import com.amazonaws.services.dynamodbv2.document.Item;
import com.amazonaws.services.dynamodbv2.document.spec.PutItemSpec;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import org.apache.commons.lang3.StringUtils;

import java.util.Map;
import java.util.UUID;

public class AddItemHandler extends BaseHandler implements RequestHandler<Map<String, String>, String> {
    @Override
    public String handleRequest(Map<String, String> stringStringMap, Context context) {
        initDb();
        String data = stringStringMap.get("data");
        int userId = Integer.parseInt(stringStringMap.get("userId"));
        if (StringUtils.isBlank(data)) {
            throw new RuntimeException("ERROR: data was not specified");
        }

        if (userId <= 0) {
            throw new RuntimeException("ERROR: userId was not specified");
        }

        var table = ddb.getTable(DYNAMODB_TABLE_NAME);
        table.putItem(new PutItemSpec().withItem(
                new Item().withString("id", UUID.randomUUID().toString().replaceAll("-",""))
                        .withString("status", "NEW")
                        .withNumber("user_id", userId)
                        .withString("data", data)
                        .withNumber("create_ts", System.currentTimeMillis())
        ));
        return "DONE";
    }
}
