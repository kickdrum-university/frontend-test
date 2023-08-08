#!/bin/bash

# Set the root directory
if [ -z "$1" ] || [ "$1" = "." ]; then
  ROOT_DIR="$(pwd)"
else
  ROOT_DIR="$1"
fi

# Install Husky if it's not already installed
if ! command -v husky &> /dev/null; then
  npm install husky --save-dev
fi

# Configure Husky to run pre-commit tests
npx husky-init
mkdir -p .husky
cat << 'EOF' > .husky/pre-commit
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

EOF
chmod +x .husky/pre-commit


cat <<'EOF' > .husky/pre-push
#!/bin/bash

# Function to detect the current platform
get_platform() {
  case "$(uname -s)" in
    Linux*)   echo "linux";;
    Darwin*)  echo "mac";;
    CYGWIN*)  echo "windows";;
    MINGW*)   echo "windows";;
    *)        echo "unsupported";;
  esac
}


USERNAME=$(git config user.name)
BRANCH_NAME=$(git symbolic-ref --short HEAD)

#Create Sonar Report and show it in the project 
SONAR_PROJECT_KEY="$USERNAME-$BRANCH_NAME-frontend"
SONAR_SERVER_URL="http://52.66.250.171:9000"  
SONAR_TOKEN="squ_75df016a1b9b75341744ba5783fc7d61f0708c93"  


# Detect the current platform
PLATFORM=$(get_platform)

# Set the appropriate SonarScanner command based on the platform
if [ "$PLATFORM" == "windows" ]; then
  SONAR_SCANNER_CMD="sonar-scanner.bat"
else
  SONAR_SCANNER_CMD="sonar-scanner"
fi

# Run the SonarScanner analysis
"$SONAR_SCANNER_CMD" \
  -Dsonar.projectKey="$SONAR_PROJECT_KEY" \
  -Dsonar.host.url="$SONAR_SERVER_URL" \
  -Dsonar.login="$SONAR_TOKEN" \
  -Dsonar.sources="./project"  

# Check if the analysis was successful
if [ $? -eq 0 ]; then
  echo "SonarScanner analysis completed successfully."
else
  echo "SonarScanner analysis failed. Please check the logs for more details."
fi

#Zip the contents of the project folder
zip -r project.zip ./project


# Set S3 bucket and object key variables
S3_BUCKET="kdu-frontend-auto-deployer"
S3_FOLDER="$USERNAME-$BRANCH_NAME"
S3_OBJECT_KEY="$S3_FOLDER/project.zip"

# Upload the project.zip file to S3
aws s3 cp ./project.zip "s3://$S3_BUCKET/$S3_OBJECT_KEY" --profile AccountLevelFullAccess-503226040441

rm ./project.zip

USER_BUCKET_NAME="$(git config user.name | tr '[:upper:]' '[:lower:]')-$(git symbolic-ref --short HEAD | tr '/' '-')"

# Generate the deployment URL
DEPLOYMENT_URL="http://$USER_BUCKET_NAME.s3-website.ap-south-1.amazonaws.com"
echo "Deployment URL: $DEPLOYMENT_URL"
echo "Please Note : It may take 2-3 minutes to deploy the project in S3. Please check after 2 minutes."

# Function to check if the JSON file exists in the bucket
check_json_file_exists() {
    local filename="$1"

    if aws s3 ls "s3://kdu-automation/frontend/$filename" --profile AccountLevelFullAccess-503226040441 &>/dev/null; then
        return 0  # File exists
    else
        return 1  # File does not exist
    fi
}

# Function to add or update key-value pair in JSON object using jq
add_key_value_to_json() {
    local key="$1"
    local value="$2"
    local json_file="$3"

    if jq --exit-status --arg key "$key" --arg value "$value" '.[$key] |= $value' "$json_file"; then
        # If the key exists, update the value
        jq --arg key "$key" --arg value "$value" '.[$key] |= $value' "$json_file" > "$json_file.tmp"
    else
        # If the key doesn't exist, add the new key-value pair to the JSON object
        jq --arg key "$key" --arg value "$value" '. + { ($key): $value }' "$json_file" > "$json_file.tmp"
    fi
    mv "$json_file.tmp" "$json_file"
}



# Update JSON file with the deployment URL
FILENAME="studentExercises.json"

# Check if the JSON file exists in the bucket
if check_json_file_exists "$FILENAME"; then
    # Download the JSON file from the bucket
    aws s3 cp "s3://kdu-automation/frontend/$FILENAME" ./temp.json --profile AccountLevelFullAccess-503226040441
else
    # Create a new empty JSON file if it doesn't exist in the bucket
    echo "{}" > ./temp.json
fi

# Add or update the key-value pair in the JSON object
KEY="$USERNAME-$BRANCH_NAME"
VALUE="$DEPLOYMENT_URL"  # Remove the escaped double quotes here

add_key_value_to_json "$KEY" "$VALUE" ./temp.json

# Upload the updated JSON file back to the bucket
aws s3 cp ./temp.json "s3://kdu-automation/frontend/$FILENAME" --profile AccountLevelFullAccess-503226040441

echo "JSON file uploaded successfully."

# Check if the upload was successful
if [ $? -eq 0 ]; then
  echo "Project uploaded to S3 bucket successfully."
else
  echo "Failed to upload the project to S3 bucket. Please check the logs for more details."
fi

EOF

chmod +x .husky/pre-push
