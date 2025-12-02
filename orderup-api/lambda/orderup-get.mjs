import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, ScanCommand, GetCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);
const tableName = 'OrderUpDB';

export const handler = async (event) => {
    try {
        let result;

        if (event.pathParameters && event.pathParameters.id) {
            const { id } = event.pathParameters;
            result = await dynamo.send(
                new GetCommand({
                    TableName: tableName,
                    Key: { id },
                })
            );
            result = result.Item || {};
        } else {
            result = await dynamo.send(
                new ScanCommand({ TableName: tableName })
            );
            result = result.Items || [];
        }

        return {
            statusCode: 200,
            body: JSON.stringify(result),
        };
    } catch (error) {
        return {
            statusCode: 400,
            body: JSON.stringify({ error: error.message }),
        };
    }
};
