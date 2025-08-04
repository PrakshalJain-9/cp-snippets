#!/bin/bash

# This script compiles and runs a C++ file, handling errors as specified.
# It receives the path to the C++ file to compile as its first argument ($1)
# and the workspace folder as its second argument ($2).

FILE_TO_COMPILE=$1
WORKSPACE_FOLDER=$2

# Define file paths based on the workspace folder
TEST_CPP_FILE="${WORKSPACE_FOLDER}/jspwTest.cpp"
EXECUTABLE="${WORKSPACE_FOLDER}/jspwTest"
INPUT_FILE="${WORKSPACE_FOLDER}/input.txt"
OUTPUT_FILE="${WORKSPACE_FOLDER}/output.txt"
ERROR_FILE="${WORKSPACE_FOLDER}/error.txt"
STATUS_FILE="${WORKSPACE_FOLDER}/status.txt"

# Ensure the log files are clean before we start
> "$ERROR_FILE"
> "$STATUS_FILE"

# --- Step 1: Compile the Code ---
# Compilation errors will now print directly to the terminal.
cp "$FILE_TO_COMPILE" "$TEST_CPP_FILE"
g++ "$TEST_CPP_FILE" -o "$EXECUTABLE"

# Check if compilation failed. If it did, stop everything.
if [ $? -ne 0 ]; then
    rm "$TEST_CPP_FILE" # Clean up the copied file
    echo "Compilation Failed." # A simple message to the terminal
    exit 1 # Stop the script
fi

# --- Step 2: Set Limits and Run the Program ---
ulimit -c 0     # Disable core dumps
ulimit -f 20000 # Set file size limit to ~20MB

# Run the compiled program.
# Redirect ONLY the program's standard error (cerr) to error.txt.
timeout 5s "$EXECUTABLE" < "$INPUT_FILE" > "$OUTPUT_FILE" 2> "$ERROR_FILE"
EXIT_CODE=$? # Capture the exit code of the 'timeout' command.

# --- Step 3: Analyze the Exit Code and Report Specific Errors ---
# This block provides special handling ONLY for time and file limit errors.

if [ $EXIT_CODE -eq 124 ] || [ $EXIT_CODE -eq 137 ]; then
    # Time limit was exceeded. Log to status file and halt immediately.
    echo "Time Limit Exceeded" > "$STATUS_FILE"
    echo "Execution Halted: Time Limit Exceeded (5 seconds)" # Message to terminal
    rm "$EXECUTABLE" # Clean up the executable
    exit 1 # Stop the script

elif [ $EXIT_CODE -eq 153 ]; then
    # File size limit was exceeded. Log to status file and halt immediately.
    echo "File Size Limit Exceeded" > "$STATUS_FILE"
    echo "Execution Halted: File Size Limit Exceeded" # Message to terminal
    rm "$EXECUTABLE" # Clean up the executable
    exit 1 # Stop the script

elif [ $EXIT_CODE -eq 0 ]; then
    # The program ran successfully. Log status and proceed to cleanup.
    echo "Execution Successful" > "$STATUS_FILE"
fi

# For any other non-zero exit code (e.g., segmentation fault), the script
# does nothing special. It will simply proceed to the cleanup step below.
# The crash message from the system will have already appeared in the terminal.
# The status.txt file will be empty, and error.txt will contain any cerr output.

# --- Step 4: Clean Up Temporary Files ---
# This step now runs for successful executions or any non-fatal runtime error.
rm "$EXECUTABLE" "$TEST_CPP_FILE"

