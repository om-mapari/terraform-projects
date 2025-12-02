import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, DeleteCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);
const tableName = 'OrderUpDB';

export const handler = async (event) => {
    try {
        const { id } = event.pathParameters;

        await dynamo.send(
            new DeleteCommand({
                TableName: tableName,
                Key: { id },
            })
        );


        return {
            statusCode: 200,
            body: JSON.stringify({ message: `Deleted order ${id}` }),
        };
    } catch (error) {
        return {
            statusCode: 400,
            body: JSON.stringify({ error: error.message }),
        };
    }
};
