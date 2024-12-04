import os
import json
import boto3
import pdfrw
from botocore.exceptions import ClientError


def handler(event, context):

    if event['httpMethod'] == 'OPTIONS':

        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type",
            },
        }

    print("Hello from LocalStack Lambda container image!")
    print(f"Received event: {event}")

    # Parse the JSON body
    try:
        body = json.loads(event.get("body", "{}"))  # Parse body safely
    except json.JSONDecodeError:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Invalid JSON format."}),
        }

    # Extract fields from JSON
    name = body.get("name")
    answer = body.get("answer")

    if not name or not answer:
        return {
            "statusCode": 204,
            "body": json.dumps({"error": "Both 'name' and 'answer' fields are required."}),
        }

    # Validate the answer (case-insensitive)
    if answer.strip().lower() != "jingles":
        return {
            "statusCode": 204,
            "body": json.dumps({"error": "Incorrect answer. Please try again!"}),
        }

    # Generate the certificate PDF
    try:
        generate_certificate(name)
    except Exception as e:
        print(f"Error generating certificate: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Failed to generate certificate."}),
        }

    # Connect to S3 on LocalStack
    s3_client = boto3.client(
        "s3",
        endpoint_url=f"http://{os.environ.get('LOCALSTACK_HOSTNAME')}:{os.environ.get('EDGE_PORT')}",
    )

    # Ensure the bucket exists
    bucket_name = "certificate-bucket"
    try:
        if not does_bucket_exist(s3_client, bucket_name):
            print(f"Bucket '{bucket_name}' does not exist, creating it.")
            s3_client.create_bucket(Bucket=bucket_name)
    except ClientError as e:
        print(f"Error creating bucket: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Failed to create or access the S3 bucket."}),
        }

    # Upload the generated file to S3
    try:
        s3_client.upload_file("/tmp/certificate.pdf", bucket_name, f"{name}_certificate.pdf")
    except ClientError as e:
        print(f"Error uploading certificate to S3: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Failed to upload certificate to S3."}),
        }

    # Return success response
    return {
        "statusCode": 200,
        "headers": {
         "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps({
            "message": (
                "Congratulations! You got the answer right. "
                f"Your certificate will be located in an S3 bucket called '{bucket_name}'."
            )
        }),
    }


def does_bucket_exist(s3_client, bucket_name):
    """Check if the given S3 bucket exists."""
    try:
        response = s3_client.list_buckets()
        for bucket in response.get("Buckets", []):
            if bucket["Name"] == bucket_name:
                return True
        return False
    except ClientError as e:
        print(f"Error checking bucket existence: {e}")
        return False


def generate_certificate(value: str):
    """Generates the highly official certificate of participation."""
    try:
        pdf = pdfrw.PdfReader("./cert_template.pdf")
        pdf.pages[0].Annots[2].update(pdfrw.PdfDict(V=value))
        pdf.pages[0].Annots[2].update(pdfrw.PdfDict(Ff=1))
        pdf.Root.AcroForm.update(pdfrw.PdfDict(NeedAppearances=pdfrw.PdfObject("true")))
        pdfrw.PdfWriter().write("/tmp/certificate.pdf", pdf)
    except Exception as e:
        print(f"Error generating PDF: {e}")
        raise
