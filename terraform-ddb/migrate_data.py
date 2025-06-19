#!/usr/bin/env python3
"""
Migration script to convert entries.json to DynamoDB format
This script transforms the JSON structure to match the DynamoDB schema
"""

import json
import re
from typing import Dict, Any, List
from decimal import Decimal

def extract_max_pain_level(pain_data: Dict[str, str]) -> int:
    """Extract the maximum pain level from pain data"""
    max_level = 0
    for location, level_str in pain_data.items():
        if level_str:
            # Extract numbers from strings like "6-7-8" or "4-5"
            numbers = re.findall(r'\d+', level_str)
            if numbers:
                max_level = max(max_level, max(int(n) for n in numbers))
    return max_level

def get_primary_medication(medications: Dict[str, str]) -> str:
    """Get the primary medication (first one or most common)"""
    if not medications:
        return ""
    # Return the first medication as primary
    return list(medications.keys())[0]

def transform_entry(date: str, timestamp: str, entry_data: Dict[str, Any]) -> Dict[str, Any]:
    """Transform a single entry to DynamoDB format"""
    
    # Handle special case for "Sleep" entries
    if timestamp == "Sleep":
        return {
            "date": date,
            "timestamp": "sleep",
            "sleep_time": entry_data,
            "entry_type": "sleep"
        }
    
    # Standard time entries
    medications = entry_data.get("Medications", {})
    pain = entry_data.get("Pain", {})
    activities = entry_data.get("Activities", {})
    
    item = {
        "date": date,
        "timestamp": timestamp,
        "medications": medications,
        "pain": pain,
        "activities": activities,
        "o2": entry_data.get("o2", ""),
        "bpr": entry_data.get("bpr", ""),
        "note": entry_data.get("note", ""),
        "entry_type": "measurement"
    }
    
    # Add GSI attributes
    primary_med = get_primary_medication(medications)
    if primary_med:
        item["medication_taken"] = primary_med
    
    max_pain = extract_max_pain_level(pain)
    if max_pain > 0:
        item["max_pain_level"] = max_pain
    
    return item

def convert_json_to_dynamodb_format(json_file_path: str) -> List[Dict[str, Any]]:
    """Convert the entire JSON file to DynamoDB format"""
    
    with open(json_file_path, 'r') as f:
        data = json.load(f)
    
    items = []
    
    for date, date_entries in data.items():
        for timestamp, entry_data in date_entries.items():
            if isinstance(entry_data, dict):
                item = transform_entry(date, timestamp, entry_data)
                items.append(item)
            else:
                # Handle sleep entries that are just strings
                item = {
                    "date": date,
                    "timestamp": timestamp.lower(),
                    "sleep_time": entry_data,
                    "entry_type": "sleep"
                }
                items.append(item)
    
    return items

def generate_batch_write_requests(items: List[Dict[str, Any]], table_name: str) -> List[Dict[str, Any]]:
    """Generate DynamoDB batch write requests"""
    
    batches = []
    batch_size = 25  # DynamoDB limit
    
    for i in range(0, len(items), batch_size):
        batch_items = items[i:i + batch_size]
        
        put_requests = []
        for item in batch_items:
            # Convert Python types to DynamoDB format
            dynamodb_item = {}
            for key, value in item.items():
                if isinstance(value, str):
                    dynamodb_item[key] = {"S": value}
                elif isinstance(value, int):
                    dynamodb_item[key] = {"N": str(value)}
                elif isinstance(value, dict):
                    if value:  # Only add non-empty dicts
                        dynamodb_item[key] = {"M": {
                            k: {"S": v} for k, v in value.items()
                        }}
                    else:
                        dynamodb_item[key] = {"M": {}}
            
            put_requests.append({
                "PutRequest": {
                    "Item": dynamodb_item
                }
            })
        
        batch = {
            "RequestItems": {
                table_name: put_requests
            }
        }
        batches.append(batch)
    
    return batches

def main():
    """Main migration function"""
    
    # Convert JSON to DynamoDB format
    items = convert_json_to_dynamodb_format("entries.json")
    
    print(f"Converted {len(items)} entries from JSON")
    
    # Save converted data for review
    with open("converted_entries.json", "w") as f:
        json.dump(items, f, indent=2, default=str)
    
    print("Saved converted data to converted_entries.json")
    
    # Generate batch write requests
    table_name = "fusion-health-entries"
    batches = generate_batch_write_requests(items, table_name)
    
    print(f"Generated {len(batches)} batch write requests")
    
    # Save batch requests
    with open("dynamodb_batch_requests.json", "w") as f:
        json.dump(batches, f, indent=2)
    
    print("Saved batch write requests to dynamodb_batch_requests.json")
    print("\nTo upload to DynamoDB, use the AWS CLI:")
    print("aws dynamodb batch-write-item --request-items file://dynamodb_batch_requests.json")
    
    # Print sample item for verification
    if items:
        print("\nSample converted item:")
        print(json.dumps(items[0], indent=2, default=str))

if __name__ == "__main__":
    main()
