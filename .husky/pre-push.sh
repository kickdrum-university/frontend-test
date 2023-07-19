#!/bin/bash

# Build the React project
npm run build

# Check if the bucket exists
USER_BUCKET_NAME="user-$(git config user.name | tr '[:upper:]' '[:lower:]')-$(git symbolic-ref --short HEAD | tr '/' '-')"
if aws s3api head-bucket --bucket $USER_BUCKET_NAME --profile AccountLevelFullAccess-503226040441 2>/dev/null; then
  echo "Bucket already exists: $USER_BUCKET_NAME"
else
  echo "Creating bucket: $USER_BUCKET_NAME"
  aws s3api create-bucket --bucket $USER_BUCKET_NAME --region ap-south-1 --create-bucket-configuration LocationConstraint=ap-south-1 --profile AccountLevelFullAccess-503226040441
  aws s3api put-public-access-block --bucket $USER_BUCKET_NAME --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false" --profile AccountLevelFullAccess-503226040441
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
  }' --profile AccountLevelFullAccess-503226040441
  aws s3api put-bucket-website --bucket $USER_BUCKET_NAME --website-configuration '{
    "ErrorDocument": {"Key": "index.html"},
    "IndexDocument": {"Suffix": "index.html"}
  }' --profile AccountLevelFullAccess-503226040441
fi

# Deploy the build to the user's branch-specific bucket
aws s3 sync build/ s3://$USER_BUCKET_NAME --profile AccountLevelFullAccess-503226040441

# Generate the deployment URL
DEPLOYMENT_URL="http://$USER_BUCKET_NAME.s3-website.ap-south-1.amazonaws.com"
echo "Deployment URL: $DEPLOYMENT_URL"

#!/bin/bash

# Function to print JSON content
print_json_content() {
  echo "JSON content in $1:"
  echo "-----------------------------"
  cat "$1"
  echo "-----------------------------"
}

# Update JSON file with the deployment URL
USERNAME=$(git config user.name)
BRANCH_NAME=$(git symbolic-ref --short HEAD)
FILENAME="${BRANCH_NAME}.json"

# Check if the JSON file exists in the bucket
if aws s3 ls s3://kdu-automation/frontend/"$FILENAME" --profile AccountLevelFullAccess-503226040441; then
  # Download the JSON file from the bucket
  aws s3 cp s3://kdu-automation/frontend/"$FILENAME" ./temp.json --profile AccountLevelFullAccess-503226040441

  # Print the existing JSON content
  print_json_content "./temp.json"

  # Add the key-value pair to the JSON object using awk
  NEW_JSON="{\"$USERNAME-$BRANCH_NAME\":\"$DEPLOYMENT_URL\"}"
  awk -v new_json="$NEW_JSON" '1;/^{/{print new_json","}' ./temp.json > ./temp2.json

  # Overwrite the original file with the updated content
  mv ./temp2.json ./temp.json

  # Print the updated JSON content
  print_json_content "./temp.json"

  # Upload the updated JSON file back to the bucket
  aws s3 cp ./temp.json s3://kdu-automation/frontend/"$FILENAME" --profile AccountLevelFullAccess-503226040441

  echo "JSON file uploaded successfully."
else
  # Create a new JSON file with the key-value pair
  echo "{\"$USERNAME-$BRANCH_NAME\":\"$DEPLOYMENT_URL\"}" > new.json

  # Print the content of the new JSON file
  print_json_content "./new.json"

  # Upload the new JSON file to the bucket
  aws s3 cp ./new.json s3://kdu-automation/frontend/"$FILENAME" --profile AccountLevelFullAccess-503226040441

  echo "JSON file uploaded successfully."
fi

