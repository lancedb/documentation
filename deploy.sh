#!/bin/bash

set -e

STAGING_BASE_URL="http://lancedb-website-staging.s3-website-us-east-1.amazonaws.com/"

CLOUDFRONT_DIST_ID="E1Y5N3Q67ZCHWH"

ENV=$1

if [ -z "$ENV" ]; then
  echo "Usage: ./deploy.sh [staging|prod]"
  exit 1
fi

if [ "$ENV" == "staging" ]; then
  BUCKET_NAME="lancedb-website-staging"

  echo "☁️ Checking if credentials is present"
  echo "Ensure AWS environment variables (lancedb-devland) are exported from https://etoai.awsapps.com/start/#/?tab=accounts"
  aws s3 ls $BUCKET_NAME

  echo "📦 Building for staging..."
  # npm run build

  echo "☁️ Uploading to S3: $BUCKET_NAME"
  aws s3 sync ./docs/site s3://$BUCKET_NAME/documentation

  echo "🌐 View site: $STAGING_BASE_URL"

elif [ "$ENV" == "prod" ]; then
  BUCKET_NAME="lancedb.com"

  echo "☁️ Checking if credentials is present"
  echo "Ensure AWS environment variables (eto) are exported from https://etoai.awsapps.com/start/#/?tab=accounts"
  aws s3 ls $BUCKET_NAME

  echo "📦 Building for production..."
  # npm run build

  echo "☁️ Uploading to S3: $BUCKET_NAME"
  aws s3 sync ./docs/site s3://$BUCKET_NAME/documentation

  echo "🚀 Invalidating CloudFront cache..."
  aws cloudfront create-invalidation --distribution-id "$CLOUDFRONT_DIST_ID" --paths "/*"

  echo "✅ Production deployment complete."

else
  echo "❌ Unknown environment: $ENV"
  exit 1
fi

