#!/bin/bash

echo "Converting each .csv file to a .txt file..."

# Loop through all files ending with .csv in the current directory
for csv_file in *.csv; do
  # Check if the file actually exists (in case no .csv files are found)
  if [ -f "$csv_file" ]; then
    # Extract the base name of the file (without the .csv extension)
    base_name=$(basename "$csv_file" .csv)

    # Define the output file name with a .txt extension
    output_txt_file="${base_name}.txt"

    echo "Converting '$csv_file' to '$output_txt_file'..."

    # Use cat to copy the content of the CSV file to the new TXT file
    cat "$csv_file" > "$output_txt_file"
  else
    echo "No .csv files found in the current directory."
    break # Exit the loop if no files are found
  fi
done

echo "Conversion complete. Check your directory for the new .txt files."