package kz.sabyrzhan.awslambdatodo;

import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBQueryExpression;
import com.amazonaws.services.dynamodbv2.document.Item;
import com.amazonaws.services.dynamodbv2.document.ItemCollection;
import com.amazonaws.services.dynamodbv2.document.QueryOutcome;
import com.amazonaws.services.dynamodbv2.document.internal.IteratorSupport;
import com.amazonaws.services.dynamodbv2.document.spec.QuerySpec;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import org.apache.commons.lang3.StringUtils;

import java.util.HashMap;
import java.util.Map;

public class GetItemsHandler extends BaseHandler implements RequestHandler<Map<String, String>, String> {
    @Override
    public String handleRequest(Map<String, String> stringStringMap, Context context) {
        initDb();
        int userId = Integer.parseInt(stringStringMap.get("userId"));
        String lastCreateTsString = stringStringMap.get("lastCreateTs");
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
        while(iterator.hasNext()) {
            Item next = iterator.next();
            System.out.println(next.getNumber("user_id") + " " + next.getString("data") + " " + next.getNumber("create_ts"));
        }
        System.out.println(query.getLastLowLevelResult().getQueryResult().getLastEvaluatedKey());
        return "Finished";
    }
}
