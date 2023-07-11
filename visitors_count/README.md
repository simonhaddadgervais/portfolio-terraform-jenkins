### BACKEND

Part of the challenge was to implement a function that counts the number of visitors on my website, and returns that number.
For that I used **Lambda** for the function,
**DynamoDB** to store the data and **APIGateway** to access that data from my website.


*
I wrote the function in **Python**. I imported the AWS SDK `boto3`, to access my table and update it
by adding 1 to my 'visitor' attribute, and then return a json response containing my visitor count: 

```py
import json
import boto3

dynamodb = boto3.resource('dynamodb', 'us-east-1')
table = dynamodb.Table('cloud-resume-challenge')


def visitors_count(event, context):
    response = table.update_item(Key={'ID': 'visitors'},
                                 AttributeUpdates={'visitors': {'Value': 1, 'Action': 'ADD'}},
                                 ReturnValues='UPDATED_NEW')

    body = {"visitors": str(response['Attributes']['visitors'])}

    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Content-Type": "application/json"
        },
        "body": json.dumps(body)
    }
```


I added some **Javascript** on my html index file, so that loading the page fetches the API,
which calls the function I just created, adds 1 to the count and return the updated count.
It looked like this :
```
<script>
        fetch('https://xf5z9o0wwh.execute-api.us-east-1.amazonaws.com/Prod/visitors_count')
            .then(response => response.json())
            .then((data) => {
                document.getElementById('visitors').innerText = data.visitors
            })
    </script>
```
I also wanted to display that count on the website, so I added in a paragraph:

```
Visitors : <span id="visitors" />
```

#### Testing

I used `mock_dynamodb` from `moto` to mock a **DynamoDB** table and test my function against it.

This was the hardest part for me, as it was the first time using moto, and I was struggling with it.
The test function was trying to call my real table and I didn't know the mocked table needed to be exactly
identical to the real table to avoid that issue.
I fixed it by naming the table, the items and everything just like the real table's, and it worked!
I could locally pytest my function with success.

The final test looks like :

```py
import json
import boto3
import pytest
from moto import mock_dynamodb


# API event here

@mock_dynamodb
def test_visitors_count(apigw_event):
    from visitors_count import app
    table_name = 'cloud-resume-challenge'
    # Create mock DynamoDB table
    dynamodb = boto3.resource('dynamodb', 'us-east-1')
    table = dynamodb.create_table(
        TableName=table_name,
        KeySchema=[{'AttributeName': 'ID', 'KeyType': 'HASH'}],
        AttributeDefinitions=[{'AttributeName': 'ID', 'AttributeType': 'S'}],
        ProvisionedThroughput={'ReadCapacityUnits': 2, 'WriteCapacityUnits': 1}
    )

    ret = app.visitors_count(apigw_event, "")
    data = json.loads(ret["body"])

    assert ret["statusCode"] == 200
    assert data == {"visitors": "1"}
```