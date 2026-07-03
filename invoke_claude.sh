#!/bin/bash

# Create a temporary file for the request
cat > /tmp/claude_request.json << 'EOL'
{
  "anthropic_version": "bedrock-2023-05-31",
  "max_tokens": 500,
  "temperature": 0.5,
  "top_p": 0.9,
  "messages": [
    {
      "role": "user",
      "content": "Explain quantum computing in simple terms"
    }
  ]
}
EOL

# Print the request for debugging
echo "=== Sending Request ==="
jq . /tmp/claude_request.json
echo "====================="

# Invoke Claude 3 Haiku model using file input
aws bedrock-runtime invoke-model \
  --model-id anthropic.claude-3-haiku-20240307-v1:0 \
  --content-type "application/json" \
  --accept "application/json" \
  --cli-binary-format raw-in-base64-out \
  --body file:///tmp/claude_request.json \
  output.json \
  --profile raj-private \
  --region eu-west-1

# Clean up the temporary file
rm -f /tmp/claude_request.json

# Display the output
if [ -f "output.json" ]; then
  echo -e "\n=== Model Response ==="
  jq -r '.content[0].text' output.json
  echo "====================="
else
  echo -e "\nError: Failed to generate output. Check the request and try again."
  
  # Run a debug command to check Bedrock access
  echo -e "\n=== Debugging Information ==="
  echo "Checking AWS Bedrock access..."
  # shellcheck disable=SC2016 # single quotes are intentional: this is a JMESPath
  # query for --query, and the backticks are literal JMESPath syntax, not shell
  # command substitution - it must not expand.
  aws bedrock list-foundation-models \
    --query 'modelSummaries[?starts_with(modelId, `anthropic.`)].{modelId: modelId, status: modelLifecycle.status, onDemand: modelLifecycle.onDemandSupported}' \
    --output table \
    --profile raj-private \
    --region eu-west-1
  
  echo -e "\nTroubleshooting steps:"
  echo "1. Verify your AWS credentials are configured correctly"
  echo "2. Check if the model ID is correct"
  echo "3. Ensure you have the necessary permissions"
  echo "4. Check the AWS Bedrock service status"
  echo -e "\nAWS Configuration:"
  echo "Profile: raj-private"
  echo "Region: eu-west-1"
  echo "Model ID: anthropic.claude-3-haiku-20240307-v1:0"
  
  echo -e "\nFor more detailed debugging, run:"
  printf '  aws --debug bedrock-runtime invoke-model \\\n    --model-id anthropic.claude-3-haiku-20240307-v1:0 \\\n    --content-type "application/json" \\\n    --accept "application/json" \\\n    --body file:///tmp/claude_request.json \\\n    output.json \\\n    --profile raj-private \\\n    --region eu-west-1\n'
fi
