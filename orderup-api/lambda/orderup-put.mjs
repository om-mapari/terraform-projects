import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);
const tableName = 'OrderUpDB';

export const handler = async (event) => {
    console.log(event)
    try {
        const requestJSON = JSON.parse(event.body);

        await dynamo.send(
            new PutCommand({
                TableName: tableName,
                Item: {
                    id: requestJSON.id,
                    pie: requestJSON.pie,
                    quantity: requestJSON.quantity,
                    customerName: requestJSON.customerName,
                    deliveryDate: requestJSON.deliveryDate,
                },
            })
        );

        return {
            statusCode: 200,
            body: JSON.stringify({ message: `Received order ${requestJSON.id}` }),
        };
    } catch (error) {
        return {
            statusCode: 400,
            body: JSON.stringify({ error: error.message }),
        };
    }
};
