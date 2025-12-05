#!/bin/bash

# Personalization Validation Script
# This script checks if you've properly personalized all configuration files
# Usage: ./validate-personalization.sh

set -e

echo "=================================="
echo "Personalization Validation Script"
echo "=================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track validation status
VALIDATION_PASSED=true

# Function to check for CHANGEME in files (excluding comments)
check_file() {
    local file=$1
    # Remove comment lines and inline comments, then check for CHANGEME
    local count=$(sed 's/#.*//' "$file" | grep -c "CHANGEME" || true)
    
    if [ "$count" -gt 0 ]; then
        echo -e "${RED}❌ FAIL${NC}: $file still contains $count occurrence(s) of CHANGEME (excluding comments)"
        echo "Lines with CHANGEME (excluding comments):"
        grep -n "CHANGEME" "$file" | grep -v "^[0-9]*:[[:space:]]*#" | sed 's/#.*//' | grep "CHANGEME" || true
        VALIDATION_PASSED=false
        return 1
    else
        echo -e "${GREEN}✅ PASS${NC}: $file"
        return 0
    fi
}

# Function to extract and display personalized values
show_config() {
    echo ""
    echo "Your Configuration:"
    echo "==================="
    
    # Extract cluster name
    CLUSTER_NAME=$(grep "^  name:" cluster-config.yaml | head -1 | awk '{print $2}')
    echo "Cluster Name: $CLUSTER_NAME"
    
    # Extract node group name
    NODE_NAME=$(grep "^  - name:" cluster-config.yaml | grep -v "^#" | head -1 | awk '{print $3}')
    echo "Node Group: $NODE_NAME"
    
    # Extract namespace
    NAMESPACE=$(grep "^  name:" app-manifests/namespace.yaml | head -1 | awk '{print $2}')
    echo "Namespace: $NAMESPACE"
    
    # Extract owner tag
    OWNER=$(grep "Owner:" cluster-config.yaml | grep -v "^#" | head -1 | awk '{print $2}')
    echo "Owner: $OWNER"
    
    echo ""
}

# Start validation
echo "Checking required files..."
echo ""

# Check if files exist
FILES=(
    "cluster-config.yaml"
    "app-manifests/namespace.yaml"
    "app-manifests/backend-deployment.yaml"
    "app-manifests/frontend-deployment.yaml"
)

for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ ERROR${NC}: File not found: $file"
        echo "Are you in the Activity4-Scripted-Setup directory?"
        exit 1
    fi
done

echo "All required files found!"
echo ""

# Check each file for CHANGEME
echo "Validating personalization..."
echo ""

check_file "cluster-config.yaml"
check_file "app-manifests/namespace.yaml"
check_file "app-manifests/backend-deployment.yaml"
check_file "app-manifests/frontend-deployment.yaml"

echo ""

# Show extracted configuration
show_config

# Check for specific patterns
echo "Pattern Validation:"
echo "==================="

# Check cluster name pattern
CLUSTER_NAME=$(grep "^  name:" cluster-config.yaml | head -1 | awk '{print $2}')
if [[ $CLUSTER_NAME =~ ^eks-[a-z]+-cluster$ ]]; then
    echo -e "${GREEN}✅ PASS${NC}: Cluster name follows pattern: $CLUSTER_NAME"
else
    echo -e "${YELLOW}⚠️  WARN${NC}: Cluster name may not follow pattern (expected: eks-<username>-cluster): $CLUSTER_NAME"
fi

# Check namespace pattern
NAMESPACE=$(grep "^  name:" app-manifests/namespace.yaml | head -1 | awk '{print $2}')
if [[ $NAMESPACE =~ ^[a-z]+-todo-app$ ]]; then
    echo -e "${GREEN}✅ PASS${NC}: Namespace follows pattern: $NAMESPACE"
else
    echo -e "${YELLOW}⚠️  WARN${NC}: Namespace may not follow pattern (expected: <username>-todo-app): $NAMESPACE"
fi

echo ""

# Check if AWS CLI is configured
echo "AWS Configuration:"
echo "=================="
if command -v aws &> /dev/null; then
    if aws sts get-caller-identity &> /dev/null; then
        IAM_ARN=$(aws sts get-caller-identity --query Arn --output text)
        IAM_USER=$(echo $IAM_ARN | awk -F'/' '{print $NF}')
        echo -e "${GREEN}✅ AWS CLI configured${NC}"
        echo "IAM User: $IAM_USER"
        
        # Extract username from IAM user (after eks-)
        if [[ $IAM_USER =~ ^eks-(.+)$ ]]; then
            EXTRACTED_USERNAME="${BASH_REMATCH[1]}"
            CONFIG_USERNAME=$(echo $CLUSTER_NAME | sed 's/eks-//g' | sed 's/-cluster//g')
            
            if [ "$EXTRACTED_USERNAME" == "$CONFIG_USERNAME" ]; then
                echo -e "${GREEN}✅ MATCH${NC}: Your IAM username ($EXTRACTED_USERNAME) matches cluster config ($CONFIG_USERNAME)"
            else
                echo -e "${YELLOW}⚠️  WARN${NC}: IAM username ($EXTRACTED_USERNAME) differs from cluster config ($CONFIG_USERNAME)"
                echo "This may cause confusion. Consider using: $EXTRACTED_USERNAME"
            fi
        fi
    else
        echo -e "${RED}❌ AWS CLI not configured${NC}"
        echo "Run: aws configure"
        VALIDATION_PASSED=false
    fi
else
    echo -e "${RED}❌ AWS CLI not installed${NC}"
    VALIDATION_PASSED=false
fi

echo ""
echo "=================================="

# Final result
if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "${GREEN}🎉 SUCCESS! All validations passed!${NC}"
    echo ""
    echo "You're ready to create your cluster:"
    echo "  eksctl create cluster -f cluster-config.yaml"
    echo ""
    exit 0
else
    echo -e "${RED}❌ VALIDATION FAILED${NC}"
    echo ""
    echo "Please fix the issues above before proceeding."
    echo "See 00-PERSONALIZATION-GUIDE.md for help."
    echo ""
    exit 1
fi

