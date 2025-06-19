# DynamoDB Health Tracking Schema

This DynamoDB configuration is designed to store health tracking data derived from `entries.json`. The schema supports efficient querying for medical monitoring and pain management tracking.

## Table Structure

### Main Table: `fusion-health-entries`

**Primary Key:**
- **Partition Key (Hash)**: `date` (String) - Date in MMDD format (e.g., "0523")
- **Sort Key (Range)**: `timestamp` (String) - Time in HHMM format (e.g., "1300")

**Item Structure:**
```json
{
  "date": "0523",                    // Partition key
  "timestamp": "1300",               // Sort key
  "medications": {                   // Map of medications taken
    "oxycodone": "5mg",
    "journavx": "100mg"
  },
  "pain": {                         // Map of pain locations and levels
    "quads": "6-7-8",
    "back": "6-7-8",
    "glutes": "6-7-8"
  },
  "activities": {                   // Map of activities performed
    "standing": 5,
    "walking": 16
  },
  "o2": "88",                       // Oxygen level (string)
  "bpr": "129/59",                  // Blood pressure reading (string)
  "note": "Pain is focused on...",  // Text notes
  "sleep": "7:39",                  // Sleep time (when present)
  "medication_taken": "oxycodone",  // GSI attribute - primary medication
  "max_pain_level": 8               // GSI attribute - highest pain level
}
```

### Secondary Table: `fusion-daily-summaries`

**Primary Key:**
- **Partition Key**: `date` (String) - Date in MMDD format

**Purpose:** Store daily aggregated data, trends, and summaries.

## Global Secondary Indexes (GSI)

### 1. Medication Index
- **Hash Key**: `medication_taken` (String)
- **Range Key**: `date` (String)  
- **Purpose**: Query all entries by medication type

**Query Examples:**
```sql
-- Find all oxycodone entries
medication_taken = "oxycodone"

-- Find oxycodone entries for specific date range
medication_taken = "oxycodone" AND date BETWEEN "0520" AND "0530"
```

### 2. Pain Level Index
- **Hash Key**: `max_pain_level` (Number)
- **Range Key**: `date` (String)
- **Purpose**: Query entries by pain severity

**Query Examples:**
```sql
-- Find all high pain entries (level 8)
max_pain_level = 8

-- Find severe pain entries in date range
max_pain_level = 8 AND date BETWEEN "0520" AND "0530"
```

## Data Mapping from JSON

The original JSON structure is flattened and enhanced for DynamoDB:

**Original JSON:**
```json
{
  "0523": {
    "1300": {
      "Medications": {"oxycodone": "5mg"},
      "Pain": {"back": "6-7-8"},
      "Activities": {},
      "o2": "88",
      "bpr": "129/59",
      "note": "Pain is focused..."
    }
  }
}
```

**DynamoDB Item:**
```json
{
  "date": {"S": "0523"},
  "timestamp": {"S": "1300"},
  "medications": {"M": {"oxycodone": {"S": "5mg"}}},
  "pain": {"M": {"back": {"S": "6-7-8"}}},
  "activities": {"M": {}},
  "o2": {"S": "88"},
  "bpr": {"S": "129/59"},
  "note": {"S": "Pain is focused..."},
  "medication_taken": {"S": "oxycodone"},
  "max_pain_level": {"N": "8"}
}
```

## Common Query Patterns

### 1. Get all entries for a specific date
``python
response = dynamodb.query(
    TableName='fusion-health-entries',
    KeyConditionExpression='#date = :date',
    ExpressionAttributeNames={'#date': 'date'},
    ExpressionAttributeValues={':date': {'S': '0523'}}
)
```

### 2. Get entries for a specific time range on a date
```python
response = dynamodb.query(
    TableName='fusion-health-entries',
    KeyConditionExpression='#date = :date AND #timestamp BETWEEN :start AND :end',
    ExpressionAttributeNames={
        '#date': 'date',
        '#timestamp': 'timestamp'
    },
    ExpressionAttributeValues={
        ':date': {'S': '0523'},
        ':start': {'S': '1200'},
        ':end': {'S': '1800'}
    }
)
```

### 3. Find all entries with specific medication
```python
response = dynamodb.query(
    TableName='fusion-health-entries',
    IndexName='medication-index',
    KeyConditionExpression='medication_taken = :med',
    ExpressionAttributeValues={':med': {'S': 'oxycodone'}}
)
```

### 4. Find high pain level entries
```python
response = dynamodb.query(
    TableName='fusion-health-entries',
    IndexName='pain-level-index',
    KeyConditionExpression='max_pain_level = :level',
    ExpressionAttributeValues={':level': {'N': '8'}}
)
```

## Cost Optimization

### Pay-Per-Request (Default)
- **Best for**: Variable, unpredictable workloads
- **Cost**: $1.25 per million read requests, $1.25 per million write requests
- **When to use**: Development, testing, or applications with sporadic usage

### Provisioned Capacity
- **Best for**: Predictable, consistent workloads  
- **Cost**: $0.25 per read capacity unit/month, $0.25 per write capacity unit/month
- **When to use**: Production with consistent usage patterns

## Security Features

1. **Server-side encryption**: Enabled by default using AWS managed keys
2. **Point-in-time recovery**: Enabled for data protection
3. **Deletion protection**: Enabled to prevent accidental deletion
4. **IAM role**: Least-privilege access for applications

## Usage Examples

### Deploy with default settings:
```bash
terraform init
terraform plan
terraform apply
```

### Deploy for development (lower cost):
```bash
terraform apply \
  -var='enable_deletion_protection=false' \
  -var='enable_point_in_time_recovery=false' \
  -var='environment=development'
```

### Deploy with provisioned capacity:
```bash
terraform apply \
  -var='billing_mode=PROVISIONED' \
  -var='read_capacity=10' \
  -var='write_capacity=5'
```

## Migration from JSON

To migrate existing data from `entries.json`:

1. **Transform the data structure**
2. **Add GSI attributes** (`medication_taken`, `max_pain_level`)
3. **Use AWS DynamoDB import** or **batch write** operations
4. **Validate data integrity** after migration

## Monitoring and Maintenance

Consider setting up:
- **CloudWatch alarms** for throttling and errors
- **Cost budgets** for spend monitoring
- **Regular backups** using point-in-time recovery
- **Performance monitoring** for query optimization

This schema provides efficient access patterns for medical data analysis while maintaining HIPAA-compliant security features.
