package kz.sabyrzhan.awslambdatodo;

import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBQueryExpression;
import com.amazonaws.services.dynamodbv2.document.Item;
import com.amazonaws.services.dynamodbv2.document.ItemCollection;
import com.amazonaws.services.dynamodbv2.document.QueryOutcome;
import com.amazonaws.services.dynamodbv2.document.internal.IteratorSupport;
import com.amazonaws.services.dynamodbv2.document.spec.QuerySpec;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPResponse;
import kz.sabyrzhan.awslambdatodo.model.Todo;
import org.apache.commons.lang3.StringUtils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class GetItemsHandler extends BaseHandler implements RequestHandler<APIGatewayV2HTTPEvent, APIGatewayV2HTTPResponse> {
    @Override
    public APIGatewayV2HTTPResponse handleRequest(APIGatewayV2HTTPEvent event, Context context) {
        initDb();
        int userId = Integer.parseInt(event.getQueryStringParameters().get("userId"));
        String lastCreateTsString = event.getQueryStringParameters().get("lastCreateTs");
        long lastCreateTs = 0;
        if (StringUtils.isNotBlank(lastCreateTsString)) {
            lastCreateTs = Long.parseLong(lastCreateTsString);
        }
        var queryExpression = new DynamoDBQueryExpression<Map<String, String>>();
        queryExpression.setScanIndexForward(false);

        var eav = new HashMap<String, Object>();
        eav.put(":userId", userId);

        var table =  ddb.getTable(DYNAMODB_TABLE_NAME);
        var querySpec = new QuerySpec()
                .withMaxResultSize(10)
                .withScanIndexForward(false)
                .withKeyConditionExpression("user_id = :userId")
                .withValueMap(eav);
        if (lastCreateTs != 0) {
            querySpec.withExclusiveStartKey("user_id", userId, "create_ts", lastCreateTs);
        }
        ItemCollection<QueryOutcome> query = table.query(querySpec);
        IteratorSupport<Item, QueryOutcome> iterator = query.iterator();
        var todoList = new ArrayList<>();
        while(iterator.hasNext()) {
            Item next = iterator.next();
            todoList.add(
                    Todo.builder()
                            .userId(next.getNumber("user_id").intValue())
                            .data(next.getString("data"))
                            .timestamp(next.getNumber("create_ts").intValue())
                            .build());
        }

        return APIGatewayV2HTTPResponse.builder()
                .withBody(gson.toJson(todoList))
                .withHeaders(Map.of("Content-Type", "application/json"))
                .withStatusCode(200)
                .build();
    }
}
