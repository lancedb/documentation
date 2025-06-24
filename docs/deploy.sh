#!/bin/bash

set -e

ENV=$1

if [ -z "$ENV" ]; then
  echo "Usage: ./deploy.sh [staging|prod]"
  exit 1
fi

if [ "$ENV" == "staging" ]; then
  # This shares the same bucket as the existing website.
  URL="http://lancedb-website-staging.s3-website-us-east-1.amazonaws.com/documentation"
  BUCKET_NAME="lancedb-website-staging"

  echo "☁️ Checking if credentials is present"
  echo "Ensure AWS environment variables (lancedb-devland) are exported from https://etoai.awsapps.com/start/#/?tab=accounts"
  aws s3 ls $BUCKET_NAME

  echo "📦 Building for staging..."
  mkdocs build -f mkdocs.yml

  echo "☁️ Uploading to S3: $BUCKET_NAME"
  aws s3 sync ./site s3://$BUCKET_NAME/documentation

  echo "🌐 View site: $URL"

elif [ "$ENV" == "prod" ]; then
  URL="https://lancedb.com/documentation"
  BUCKET_NAME="lancedb-docs"
  CLOUDFRONT_DIST_ID="E1Y5N3Q67ZCHWH"

  echo "☁️ Checking if credentials is present"
  echo "Ensure AWS environment variables (eto) are exported from https://etoai.awsapps.com/start/#/?tab=accounts"
  aws s3 ls $BUCKET_NAME

  echo "📦 Building for production..."
  sed -i.bak 's|http://lancedb-website-staging.s3-website-us-east-1.amazonaws.com|https://lancedb.com|' mkdocs.yml
  mkdocs build -f mkdocs.yml
  mv mkdocs.yml.bak mkdocs.yml

  echo "☁️ Uploading to S3: $BUCKET_NAME"
  aws s3 sync ./site s3://$BUCKET_NAME/documentation

  echo "🚀 Invalidating CloudFront cache..."
  aws cloudfront create-invalidation --distribution-id "$CLOUDFRONT_DIST_ID" --paths "/documentation/*" "/documentation"

  echo "✅ Production deployment complete."

  echo "🌐 View site: $URL"

else
  echo "❌ Unknown environment: $ENV"
  exit 1
fi

