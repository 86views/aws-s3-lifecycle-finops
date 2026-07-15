#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🚀 Starting Asset Deployment to S3${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Validate required variables
if [ -z "$BUCKET_NAME" ]; then
    echo -e "${RED}❌ Error: BUCKET_NAME environment variable not set${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Deployment Configuration:${NC}"
echo "  Bucket: $BUCKET_NAME"
echo "  Environment: ${ENVIRONMENT:-dev}"
echo "  Deployment ID: ${DEPLOYMENT_ID:-unknown}"

# Create deployment directory
DEPLOY_DIR="deploy_$(date +%s)"
mkdir -p $DEPLOY_DIR
echo -e "${GREEN}✅ Created deployment directory: $DEPLOY_DIR${NC}"

# ============================================
# 1. HANDLE TEST.TXT FROM TEMPLATES
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📄 Processing test.txt files...${NC}"

# Copy your existing test.txt from templates
if [ -f "templates/test.txt" ]; then
    echo "  Found templates/test.txt - copying..."
    cp templates/test.txt $DEPLOY_DIR/test.txt
    
    # Also create versioned copies
    for i in {1..5}; do
        # Create versioned files based on your test.txt
        sed "s/Version .*/Version $i - $(date +'%Y-%m-%d %H:%M:%S')/" templates/test.txt > $DEPLOY_DIR/test_v${i}.txt
        echo "  ✅ Created test_v${i}.txt"
    done
    
    # Create additional test files with different content
    echo "Environment: ${ENVIRONMENT:-dev}" > $DEPLOY_DIR/test_env.txt
    echo "Deployment: ${DEPLOYMENT_ID:-unknown}" > $DEPLOY_DIR/test_deploy.txt
    echo "Timestamp: $(date -Iseconds)" > $DEPLOY_DIR/test_timestamp.txt
    
    echo -e "${GREEN}✅ Processed test.txt and created versions${NC}"
else
    echo -e "${YELLOW}⚠️  templates/test.txt not found - creating default${NC}"
    # Create default test.txt
    cat > $DEPLOY_DIR/test.txt << EOF
Test File
Environment: ${ENVIRONMENT:-dev}
Deployment ID: ${DEPLOYMENT_ID:-unknown}
Generated: $(date -Iseconds)
EOF
    
    # Create versions
    for i in {1..5}; do
        cat > $DEPLOY_DIR/test_v${i}.txt << EOF
Version ${i}
Environment: ${ENVIRONMENT:-dev}
Deployment ID: ${DEPLOYMENT_ID:-unknown}
Generated: $(date -Iseconds)
EOF
    done
fi

# ============================================
# 2. HANDLE INDEX.HTML
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🌐 Processing index.html...${NC}"

if [ -f "templates/index.html" ]; then
    sed -e "s/\${ENVIRONMENT}/${ENVIRONMENT:-dev}/g" \
        -e "s/\${DEPLOYMENT_ID}/${DEPLOYMENT_ID:-unknown}/g" \
        -e "s/\${TIMESTAMP}/$(date -Iseconds)/g" \
        -e "s/\${PROJECT}/${PROJECT:-MyProject}/g" \
        templates/index.html > $DEPLOY_DIR/index.html
    echo -e "${GREEN}✅ Generated index.html from template${NC}"
else
    # Create default index.html
    cat > $DEPLOY_DIR/index.html << EOF
<!DOCTYPE html>
<html>
<head><title>${PROJECT:-MyProject}</title></head>
<body>
    <h1>🚀 ${PROJECT:-MyProject}</h1>
    <p>Environment: ${ENVIRONMENT:-dev}</p>
    <p>Deployment: ${DEPLOYMENT_ID:-unknown}</p>
</body>
</html>
EOF
    echo -e "${GREEN}✅ Created default index.html${NC}"
fi

# ============================================
# 3. UPLOAD TO S3
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📤 Uploading to S3...${NC}"

# Upload test.txt
aws s3 cp $DEPLOY_DIR/test.txt s3://$BUCKET_NAME/test.txt \
    --metadata "environment=${ENVIRONMENT:-dev},deployment=${DEPLOYMENT_ID:-unknown},source=templates" \
    --metadata-directive REPLACE
echo -e "${GREEN}✅ Uploaded test.txt${NC}"

# Upload versioned test files
for file in $DEPLOY_DIR/test_v*.txt; do
    filename=$(basename "$file")
    version=${filename#test_v}
    version=${version%.txt}
    aws s3 cp "$file" "s3://$BUCKET_NAME/$filename" \
        --metadata "version=$version,environment=${ENVIRONMENT:-dev},deployment=${DEPLOYMENT_ID:-unknown}" \
        --metadata-directive REPLACE
    echo -e "${GREEN}✅ Uploaded $filename${NC}"
done

# Upload additional test files
for file in $DEPLOY_DIR/test_*.txt; do
    if [ -f "$file" ] && [[ ! "$file" =~ test_v[0-9]+\.txt$ ]]; then
        filename=$(basename "$file")
        aws s3 cp "$file" "s3://$BUCKET_NAME/$filename" \
            --metadata "environment=${ENVIRONMENT:-dev},deployment=${DEPLOYMENT_ID:-unknown}" \
            --metadata-directive REPLACE
        echo -e "${GREEN}✅ Uploaded $filename${NC}"
    fi
done

# Upload index.html
aws s3 cp $DEPLOY_DIR/index.html s3://$BUCKET_NAME/index.html \
    --content-type text/html \
    --cache-control "max-age=3600" \
    --metadata "environment=${ENVIRONMENT:-dev},deployment=${DEPLOYMENT_ID:-unknown}" \
    --metadata-directive REPLACE
echo -e "${GREEN}✅ Uploaded index.html${NC}"

# Upload any other assets
if [ -d "templates/assets" ]; then
    echo "📦 Uploading assets..."
    aws s3 sync templates/assets/ s3://$BUCKET_NAME/assets/ \
        --cache-control "max-age=86400" \
        --metadata "environment=${ENVIRONMENT:-dev}"
    echo -e "${GREEN}✅ Uploaded assets${NC}"
fi

# ============================================
# 4. CREATE DEPLOYMENT MANIFEST
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📋 Creating deployment manifest...${NC}"

cat > $DEPLOY_DIR/deployment.json << EOF
{
    "deployment_id": "${DEPLOYMENT_ID:-unknown}",
    "environment": "${ENVIRONMENT:-dev}",
    "timestamp": "$(date -Iseconds)",
    "bucket": "${BUCKET_NAME}",
    "github_run": "${GITHUB_RUN_ID:-unknown}",
    "github_sha": "${GITHUB_SHA:-unknown}",
    "files": $(aws s3 ls s3://$BUCKET_NAME/ --recursive | jq -R -s -c 'split("\n") | map(select(length>0))')
}
EOF

aws s3 cp $DEPLOY_DIR/deployment.json s3://$BUCKET_NAME/deployment_${DEPLOYMENT_ID:-unknown}.json \
    --content-type application/json \
    --metadata "environment=${ENVIRONMENT:-dev}"
echo -e "${GREEN}✅ Created deployment manifest${NC}"

# ============================================
# 5. VERIFICATION
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🔍 Verifying deployment...${NC}"

echo "Files uploaded:"
aws s3 ls s3://$BUCKET_NAME/ --recursive --human-readable | grep -E "test|index" || echo "No test files found"

# ============================================
# 6. SUMMARY
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ DEPLOYMENT COMPLETE!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "📦 Bucket: ${BUCKET_NAME}"
echo -e "🌍 Environment: ${ENVIRONMENT:-dev}"
echo -e "🆔 Deployment ID: ${DEPLOYMENT_ID:-unknown}"
echo -e "📄 Files uploaded:"
echo "   • test.txt (original from templates)"
echo "   • test_v1.txt through test_v5.txt (versioned)"
echo "   • test_env.txt (environment info)"
echo "   • test_deploy.txt (deployment info)"
echo "   • test_timestamp.txt (timestamp)"
echo "   • index.html"
echo "   • deployment_${DEPLOYMENT_ID:-unknown}.json"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Cleanup
rm -rf $DEPLOY_DIR
echo -e "${GREEN}🧹 Cleaned up temporary files${NC}"