package kz.sabyrzhan.awslambdatodo;

import com.amazonaws.services.dynamodbv2.document.Item;
import com.amazonaws.services.dynamodbv2.document.spec.PutItemSpec;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPResponse;
import org.apache.commons.lang3.StringUtils;

import java.util.Map;
import java.util.UUID;

public class AddItemHandler extends BaseHandler implements RequestHandler<APIGatewayV2HTTPEvent, APIGatewayV2HTTPResponse> {
    @Override
    public APIGatewayV2HTTPResponse handleRequest(APIGatewayV2HTTPEvent event, Context context) {
        initDb();
        var jsonBody = gson.fromJson(event.getBody(), Map.class);
        String data = (String) jsonBody.get("data");
        int userId = Integer.parseInt((String) jsonBody.get("userId"));
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

        return APIGatewayV2HTTPResponse.builder()
                .withBody(gson.toJson(Map.of("status", 200)))
                .withHeaders(Map.of("Content-Type", "application/json"))
                .withStatusCode(200)
                .build();
    }
}
