import json
import boto3

# Get the dynamodb table
dynamodb = boto3.resource('dynamodb', 'us-east-1')
table = dynamodb.Table('VisitCountPortfolio')


def visitors_count(event, context):
    # Check if 'visitors' attribute exists in DynamoDB
    check_item = table.get_item(Key={'ID': 'visitors'})
    if 'Item' in check_item:
        # If 'visitors' attribute exists, update the value  by +1
        table.update_item(Key={'ID': 'visitors'},
                          AttributeUpdates={'visitors': {'Value': 1, 'Action': 'ADD'}},
                          ReturnValues='UPDATED_NEW')
        response = table.get_item(Key={'ID': 'visitors'})
    else:
        # If 'visitors' attribute doesn't exist, initialize with the base value : 1
        # For first infra setup, the item doesn't exist yet
        table.put_item(Item={'ID': 'visitors', 'visitors': 1})
        response = table.get_item(Key={'ID': 'visitors'})

    # Get the item
    body = {"visitors": str(response['Item']['visitors'])}

    # Return a json response with the count in body
    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Content-Type": "application/json"
        },
        "body": json.dumps(body)
    }
