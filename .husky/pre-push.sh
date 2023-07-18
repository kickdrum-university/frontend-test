#!/bin/bash

# Build the React project
npm run build

# Check if the bucket exists
USER_BUCKET_NAME="user-$(git config user.name | tr '[:upper:]' '[:lower:]')-$(git symbolic-ref --short HEAD | tr '/' '-')"
if aws s3api head-bucket --bucket $USER_BUCKET_NAME 2>/dev/null; then
  echo "Bucket already exists: $USER_BUCKET_NAME"
else
  echo "Creating bucket: $USER_BUCKET_NAME"
  aws s3api create-bucket --bucket $USER_BUCKET_NAME --region ap-south-1 --create-bucket-configuration LocationConstraint=ap-south-1
  aws s3api put-public-access-block --bucket $USER_BUCKET_NAME --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
  aws s3api put-bucket-policy --bucket $USER_BUCKET_NAME --policy '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::'"$USER_BUCKET_NAME"'/*"
      }
    ]
  }'
  aws s3api put-bucket-website --bucket $USER_BUCKET_NAME --website-configuration '{
    "ErrorDocument": {"Key": "index.html"},
    "IndexDocument": {"Suffix": "index.html"}
  }'
fi

# Deploy the build to the user's branch-specific bucket
aws s3 sync build/ s3://$USER_BUCKET_NAME

# Generate the deployment URL
DEPLOYMENT_URL="http://$USER_BUCKET_NAME.s3-website.ap-south-1.amazonaws.com"
echo "Deployment URL: $DEPLOYMENT_URL"

# Update JSON file with the deployment URL
# Check if the JSON file exists in the bucket
if aws s3 ls s3://kdu-automation/frontend/$(git symbolic-ref --short HEAD).json; then
  # Download the JSON file from the bucket
  aws s3 cp s3://kdu-automation/frontend/$(git symbolic-ref --short HEAD).json ./temp.json
  
  # Add the key-value pair to the JSON file
  jq --arg username "$(git config user.name)-$(git symbolic-ref --short HEAD)" --arg url "$DEPLOYMENT_URL" '. + {($username): $url}' temp.json > updated.json
  
  # Upload the updated JSON file back to the bucket
  aws s3 cp ./updated.json s3://kdu-automation/frontend/$(git symbolic-ref --short HEAD).json
else
  # Create a new JSON file with the key-value pair
  echo "{\"$(git config user.name)-$(git symbolic-ref --short HEAD)\":\"$DEPLOYMENT_URL\"}" > new.json
  
  # Upload the new JSON file to the bucket
  aws s3 cp ./new.json s3://kdu-automation/frontend/$(git symbolic-ref --short HEAD).json
fi
