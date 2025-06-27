#!/bin/bash

# Get the current task ID
function con-tainer() {
  echo "Fetching current task ID..."
  TASK_ID=$(aws ecs list-tasks --cluster fusion --service-name fusion --query 'taskArns[0]' --output text | cut -d'/' -f3)

  echo "Connecting to task: $TASK_ID"

  # Connect to the container
  aws ecs execute-command \
    --region us-west-2 \
    --cluster fusion \
    --container PSUniversal \
    --command "/bin/bash" \
    --interactive \
    --task $TASK_ID
}
