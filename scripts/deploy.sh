#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🚀 Starting Asset Deployment to S3${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Validate inputs
if [ -z "$BUCKET_NAME" ]; then
  echo -e "${RED}❌ Error: BUCKET_NAME is not set${NC}"
  exit 1
fi

echo -e "${YELLOW}📋 Config → Bucket: $BUCKET_NAME | Env: ${ENVIRONMENT:-dev} | ID: ${DEPLOYMENT_ID:-unknown}${NC}"

DEPLOY_DIR="deploy_$(date +%s)"
mkdir -p "$DEPLOY_DIR"

# ========================
# Process index.html
# ========================
if [ -f "templates/index.html" ]; then
  echo -e "${YELLOW}🌐 Processing index.html...${NC}"

  sed \
    -e "s|\${ENVIRONMENT}|${ENVIRONMENT:-dev}|g" \
    -e "s|\${DEPLOYMENT_ID}|${DEPLOYMENT_ID:-unknown}|g" \
    -e "s|\${TIMESTAMP}|$(date -Iseconds)|g" \
    -e "s|\${GITHUB_SHA}|${GITHUB_SHA}|g" \
    -e "s|\${GITHUB_ACTOR}|${GITHUB_ACTOR}|g" \
    -e "s|\${GITHUB_REF_NAME}|${GITHUB_REF_NAME}|g" \
    -e "s|\${GITHUB_REPOSITORY}|${GITHUB_REPOSITORY}|g" \
    -e "s|\${BADGE_COLOR}|$( [ "${ENVIRONMENT}" = "prod" ] && echo "#10B981" || echo "#3B82F6" )|g" \
    templates/index.html > "$DEPLOY_DIR/index.html"

  echo -e "${GREEN}✅ index.html prepared${NC}"
fi

# ========================
# Process test files
# ========================
echo -e "${YELLOW}📄 Processing test files...${NC}"

if [ -f "templates/test.txt" ]; then
  cp "templates/test.txt" "$DEPLOY_DIR/test.txt"
else
  echo "Test file from deployment ${DEPLOYMENT_ID}" > "$DEPLOY_DIR/test.txt"
fi

# Create versioned files
for i in {1..3}; do
  cp "$DEPLOY_DIR/test.txt" "$DEPLOY_DIR/test_v${i}.txt"
  echo "Version $i - $(date)" >> "$DEPLOY_DIR/test_v${i}.txt"
done

# ========================
# Upload to S3
# ========================
echo -e "${YELLOW}📤 Uploading to S3...${NC}"

# index.html
if [ -f "$DEPLOY_DIR/index.html" ]; then
  aws s3 cp "$DEPLOY_DIR/index.html" "s3://$BUCKET_NAME/index.html" \
    --content-type text/html \
    --cache-control max-age=3600 \
    --metadata "environment=${ENVIRONMENT},deployment=${DEPLOYMENT_ID}"
fi

# test files
aws s3 cp "$DEPLOY_DIR/test.txt" "s3://$BUCKET_NAME/test.txt" \
  --metadata "environment=${ENVIRONMENT},source=templates"

for file in "$DEPLOY_DIR"/test_v*.txt; do
  aws s3 cp "$file" "s3://$BUCKET_NAME/$(basename "$file")" \
    --metadata "environment=${ENVIRONMENT},versioned=true"
done

# Other assets if any
if [ -d "templates/assets" ]; then
  aws s3 sync templates/assets/ "s3://$BUCKET_NAME/assets/" --cache-control max-age=86400
fi

echo -e "${GREEN}✅ All files uploaded successfully${NC}"

# Cleanup
rm -rf "$DEPLOY_DIR"
echo -e "${GREEN}🧹 Cleanup completed${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 Deployment Finished!${NC}"