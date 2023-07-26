#!/bin/bash

# Set the root directory
if [ -z "$1" ] || [ "$1" = "." ]; then
  ROOT_DIR="$(pwd)"
else
  ROOT_DIR="$1"
fi

# Install Husky if it's not already installed
if ! command -v husky &> /dev/null
then
  npm install husky --save-dev
fi

cd "$ROOT_DIR"
npx husky-init
mkdir -p .husky


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

# Change to the root directory of your project (if necessary)
# cd /path/to/your/project

# Detect the current platform
PLATFORM=$(get_platform)

# Set the appropriate SonarScanner command based on the platform
if [ "$PLATFORM" == "windows" ]; then
  SONAR_SCANNER_CMD="sonar-scanner.bat"
else
  SONAR_SCANNER_CMD="sonar-scanner"
fi

# Build the project (if necessary)
# Add your build command here if required for your project

# Run the SonarScanner analysis
"$SONAR_SCANNER_CMD" \
  -Dsonar.projectKey="$SONAR_PROJECT_KEY" \
  -Dsonar.host.url="$SONAR_SERVER_URL" \
  -Dsonar.login="$SONAR_TOKEN" \
  -Dsonar.sources="$ROOT_DIR"  # Use the root directory of your project for HTML, CSS, JS files

# Check if the analysis was successful
if [ $? -eq 0 ]; then
  echo "SonarScanner analysis completed successfully."
else
  echo "SonarScanner analysis failed. Please check the logs for more details."
fi

# Set S3 bucket and folder variables
S3_BUCKET="kdu-automation"
FOLDER_NAME="builds"
S3_FOLDER="$USERNAME-$BRANCH_NAME"

# Upload HTML, CSS, and JS files to S3
aws s3 sync "$ROOT_DIR" "s3://$S3_BUCKET/$FOLDER_NAME/$S3_FOLDER" --delete --profile AccountLevelFullAccess-503226040441

USER_BUCKET_NAME="user-$(git config user.name | tr '[:upper:]' '[:lower:]')-$(git symbolic-ref --short HEAD | tr '/' '-')"

# Generate the deployment URL
DEPLOYMENT_URL="http://$USER_BUCKET_NAME.s3-website.ap-south-1.amazonaws.com"
echo "Deployment URL: $DEPLOYMENT_URL"

EOF

chmod +x .husky/pre-push
