# lambda/document_processor.py

import json
import boto3
import os
from typing import Dict, Any

def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda function to process documents uploaded to S3.
    Extracts text, generates embeddings, and stores in vector database.
    """
    
    s3 = boto3.client('s3')
    bedrock = boto3.client('bedrock-runtime')
    secrets = boto3.client('secretsmanager')
    
    try:
        # Get database credentials
        secret_arn = os.environ['DB_SECRET_ARN']
        secret_response = secrets.get_secret_value(SecretId=secret_arn)
        db_creds = json.loads(secret_response['SecretString'])
        
        # Process S3 event
        for record in event['Records']:
            bucket = record['s3']['bucket']['name']
            key = record['s3']['object']['key']
            
            print(f"Processing document: {bucket}/{key}")
            
            # Download document
            response = s3.get_object(Bucket=bucket, Key=key)
            document_content = response['Body'].read()
            
            # Extract text (implement based on document type)
            text_content = extract_text(document_content, key)
            
            # Generate embeddings
            embeddings = generate_embeddings(bedrock, text_content)
            
            # Store in vector database
            store_embeddings(db_creds, key, text_content, embeddings)
            
            print(f"Successfully processed: {key}")
        
        return {
            'statusCode': 200,
            'body': json.dumps('Documents processed successfully')
        }
        
    except Exception as e:
        print(f"Error processing documents: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }

def extract_text(content: bytes, filename: str) -> str:
    """Extract text from document based on file type."""
    # Implement text extraction logic
    # For PDF: use PyPDF2 or similar
    # For DOCX: use python-docx
    # For TXT: decode directly
    return "Extracted text content"

def generate_embeddings(bedrock_client, text: str) -> list:
    """Generate embeddings using Bedrock."""
    model_id = os.environ['EMBEDDING_MODEL']
    
    response = bedrock_client.invoke_model(
        modelId=model_id,
        body=json.dumps({
            "inputText": text
        })
    )
    
    result = json.loads(response['body'].read())
    return result['embedding']

def store_embeddings(db_creds: dict, document_id: str, text: str, embeddings: list):
    """Store embeddings in PostgreSQL with pgvector."""
    import psycopg2
    
    conn = psycopg2.connect(
        host=db_creds['host'],
        port=db_creds['port'],
        database=db_creds['dbname'],
        user=db_creds['username'],
        password=db_creds['password']
    )
    
    with conn.cursor() as cur:
        # Insert into vector table
        cur.execute("""
            INSERT INTO documents (id, content, embedding)
            VALUES (%s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET
                content = EXCLUDED.content,
                embedding = EXCLUDED.embedding,
                updated_at = NOW()
        """, (document_id, text, embeddings))
    
    conn.commit()
    conn.close()