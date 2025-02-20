import json
import boto3


rekognition = boto3.client('rekognition')
s3 = boto3.client('s3')

def lambda_handler(event, context):
    #Extract bucket and object info
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    print(bucket)
    print(key)
    response = rekognition.detect_labels(
        Image={
            'S3Object': {
                'Bucket': bucket,
                'Name': key,
            }
        },
        MaxLabels=10,
        MinConfidence=95
    )
    labels = response['Labels']
    print(f"Detected labels for {key} in bucket {bucket}")
    for label in labels:
        print(f"Label: {label['Name']}, Confidence: {label['Confidence']}")
    return {
        'statusCode': 200,
        'body': json.dumps('Processed Images with label and their score')
    }
