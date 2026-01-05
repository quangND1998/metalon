#!/usr/bin/env python3
"""
Transformer script to convert invalid MySQL datetime values (0000-00-00 00:00:00) to NULL
This script reads from stdin and writes to stdout, following Singer protocol
"""

import sys
import json
import re

def is_invalid_datetime(value):
    """Check if a value is an invalid MySQL datetime that needs to be converted to NULL"""
    if value is None:
        return False
    
    # Convert to string for checking
    value_str = str(value).strip()
    
    # Check for invalid MySQL datetime patterns
    # Matches: 0000-00-00, 0000-00-00 00:00:00, 0000-00-00 00:00:00.000000, etc.
    invalid_patterns = [
        r'^0000-00-00(\s+00:00:00(\.\d+)?)?$',  # Standard invalid datetime
        r'^0000-00-00',  # Any value starting with 0000-00-00
        r'^\d{4}-00-00',  # Any date with month=00 or day=00
        r'^\d{4}-\d{2}-00',  # Any date with day=00
    ]
    
    for pattern in invalid_patterns:
        if re.match(pattern, value_str):
            return True
    
    return False

def transform_datetime(value):
    """Convert invalid datetime values to None"""
    if is_invalid_datetime(value):
        return None
    return value

def is_datetime_field_name(key):
    """Check if a field name suggests it's a datetime field"""
    key_lower = key.lower()
    return (
        'date' in key_lower or 
        'time' in key_lower or
        key_lower.endswith('_at') or  # created_at, updated_at, etc.
        key_lower.endswith('_on') or  # created_on, updated_on, etc.
        key_lower.endswith('_dt') or  # created_dt, updated_dt, etc.
        key_lower.endswith('_ts')     # created_ts, updated_ts, etc.
    )

def is_datetime_value(value):
    """Check if a value looks like a datetime string"""
    if not isinstance(value, str):
        return False
    
    value_str = value.strip()
    
    # Check for common datetime patterns: YYYY-MM-DD HH:MM:SS or YYYY-MM-DD
    datetime_pattern = r'^\d{4}-\d{2}-\d{2}(\s+\d{2}:\d{2}:\d{2}(\.\d+)?)?$'
    return bool(re.match(datetime_pattern, value_str))

def transform_record(record):
    """Transform a record message"""
    if record.get('type') != 'RECORD':
        return record
    
    if 'record' not in record:
        return record
    
    # Transform ALL fields that are datetime fields or have datetime values
    for key, value in record['record'].items():
        # Skip if already None
        if value is None:
            continue
        
        # Check if this field should be treated as datetime
        is_datetime = is_datetime_field_name(key) or is_datetime_value(value)
        
        if is_datetime:
            transformed = transform_datetime(value)
            if transformed != value:  # Only update if changed
                record['record'][key] = transformed
    
    return record

def main():
    """Main function to process Singer messages"""
    for line in sys.stdin:
        try:
            message = json.loads(line.strip())
            transformed = transform_record(message)
            print(json.dumps(transformed))
            sys.stdout.flush()
        except json.JSONDecodeError:
            # If it's not JSON, pass through as-is
            print(line, end='')
            sys.stdout.flush()
        except Exception as e:
            # Log error but continue
            sys.stderr.write(f"Error transforming message: {e}\n")
            sys.stderr.flush()

if __name__ == '__main__':
    main()

