import boto3
import json
from datetime import datetime


rekognition = boto3.client('rekognition')
dynamodb = boto3.resource('dynamodb')


table = dynamodb.Table('rekognitionresults')


custom_model_arn = #your-rekognition-custom-label-arn-here

def process_handler(event, context):
    try:
       
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        
       
        response = rekognition.detect_custom_labels(
            ProjectVersionArn=custom_model_arn,
            Image={'S3Object': {'Bucket': bucket, 'Name': key}},
            MinConfidence=75  
        )
        
      
        for label in response.get('CustomLabels', []):
            item_type = label['Name']
            count = label.get('Instances', [])
            
            item_count = len(count)
            
        
            ttl_timestamp = int(datetime.timestamp(datetime.now())) + 3600 
            
        
            table.put_item(
                Item={
                    'item_type': item_type,
                    'count': item_count,
                    'timestamp': ttl_timestamp  
                }
            )
        
        
        return {
            'statusCode': 200,
            'body': json.dumps('Successfully processed and stored recognition data.')
        }

    except Exception as e:
     
        print(f"Error processing image {key} from bucket {bucket}: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Failed to process image: {e}")
        }
