package kz.sabyrzhan.awslambdatodo;

import com.amazonaws.regions.Regions;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDB;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClientBuilder;
import com.amazonaws.services.dynamodbv2.document.DynamoDB;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

public abstract class BaseHandler {
    protected DynamoDB ddb;
    protected String DYNAMODB_TABLE_NAME = "todolist";
    protected Gson gson = new GsonBuilder().setPrettyPrinting().create();

    protected void initDb() {
        final AmazonDynamoDB ddb = AmazonDynamoDBClientBuilder.standard().withRegion(Regions.US_EAST_1.getName()).build();
        this.ddb = new DynamoDB(ddb);
    }
}
