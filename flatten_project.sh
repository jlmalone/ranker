#!/bin/bash

# Define the output file
output_file="combined_project_code.txt"

# Clear the content of the output file if it exists
> "$output_file"

# Find all .swift, .txt, and .md files recursively from the current directory, excluding the output file
find . \( -name "*.swift" -o -name "*.txt" -o -name "*.md" \) ! -name "$output_file" | while read -r file; do
  echo "Processing $file..."
  
  # Add the file name as a header in the output file
  echo -e "\n\n// File: $file\n" >> "$output_file"
  
  # Append the contents of the file to the output file
  cat "$file" >> "$output_file"
  
  # Add a separator between files
  echo -e "\n// End of $file\n" >> "$output_file"
done

echo "All .swift, .txt, and .md files have been combined into $output_file"
