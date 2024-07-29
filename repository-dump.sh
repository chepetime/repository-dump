#!/bin/bash

# Description:
# This script clones a specified GitHub repository into a temporary directory,
# aggregates the contents of all files (excluding specified files and directories) into a single .txt file,
# compresses the .txt file, and saves both the .txt and .txt.gz files in an output directory.
# It also generates a directory tree listing up to 3 levels deep and adds it to the .txt file.
# It ensures the temporary repository directory is cleaned up after execution.

echo
echo "[START] Starting the repository dump script..."

# Function to clean up the temporary repository directory
cleanup() {
    if [ -d "$repo_path" ]; then
        echo
        echo "[CLEANUP] Cleaning up the temporary repository directory..."
        rm -rf "$repo_path"
        if [ $? -eq 0 ]; then
            echo "[CLEANUP] Temporary repository directory successfully deleted."
        else
            echo "[CLEANUP] Failed to delete the temporary repository directory."
        fi
    fi
}

# Function to handle errors
error_exit() {
    echo
    echo "[ERROR] An error occurred. Exiting."
    cleanup
    exit 1
}

# Function to exit successfully
success_exit() {
    echo
    echo "[SUCCESS] Script executed successfully."
    cleanup
    exit 0
}

# Check if required tools are installed
check_dependencies() {
    echo
    echo "[CHECK] Checking for required dependencies..."
    command -v git >/dev/null 2>&1 || { echo "[CHECK] git is required but it's not installed. Exiting."; exit 1; }
    command -v tree >/dev/null 2>&1 || { echo "[CHECK] tree is required but it's not installed. Exiting."; exit 1; }
    command -v gzip >/dev/null 2>&1 || { echo "[CHECK] gzip is required but it's not installed. Exiting."; exit 1; }
    echo "[CHECK] All required dependencies are installed."
}

# Ensure the script works in Unix-like environments
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo
    echo "[CHECK] This script is designed to run in a Unix-like environment. Please use Git Bash or a similar environment on Windows."
    exit 1
fi

# Check if a repository URL is provided
if [ $# -eq 0 ]; then
    read -p "Please provide a GitHub repository URL: " repo_url
else
    repo_url=$1
fi

# Check if the provided URL is valid
if [[ ! $repo_url =~ ^https:\/\/github\.com\/[^\/]+\/[^\/]+(\.git)?$ ]]; then
    echo
    echo "[CHECK] Invalid GitHub repository URL. Please provide a valid URL."
    exit 1
fi

# Extract the repository name
repo_name=$(basename $repo_url .git)

# Define paths
script_dir=$(pwd)
output_dir="$script_dir/output"
repo_path=$(mktemp -d -t "${repo_name}_repo")
datetime=$(date +"%Y_%m_%d_%H_%M_%S")

# Create necessary directories
mkdir -p "$output_dir"

# Set up trap to clean up the repository on exit or error
trap error_exit ERR
trap cleanup EXIT

# Check dependencies
check_dependencies

echo
echo "[CLONE] Cloning repository $repo_url..."
git clone --depth=1 "$repo_url" "$repo_path" || error_exit
echo "[CLONE] Repository cloned successfully."

cd "$repo_path" || error_exit
last_commit_hash=$(git rev-parse --short HEAD)
last_commit_date=$(git log -1 --format=%cd)
last_commit_message=$(git log -1 --format=%B)

# Define the output file name
output_file="$output_dir/${repo_name}_${last_commit_hash}_${datetime}.txt"
compressed_output_file="${output_file}.gz"

# Buffer for aggregated content
buffer="\n"

# Function to dump the contents of a file into the buffer
dump_file() {
    local file=$1
    if [ -f "$file" ]; then
        buffer+="\n=========================\n"
        buffer+="File: $file\n"
        buffer+="=========================\n"
        buffer+="$(cat "$file")"
    fi
}

echo
echo "[AGGREGATE] Finding and processing files..."

# Find files based on the criteria
files=$(find . -type f \
    ! -path '*/.git/*' \
    ! -path '*/node_modules/*' \
    ! -path '*/build/*' \
    ! -path '*/output/*' \
    ! -path '*/.yarn/*' \
    ! -path '*/temp/*' \
    ! -path '*/.vscode/*' \
    ! -name '*-lock*' \
    ! -name '.env' \
    ! -name 'pnpm-lock.yaml' \
    ! -name 'yarn.lock' \
    ! -name 'package-lock.json' \
    ! -name '.*.swp' \
    ! -name '.DS_Store' \
    ! -name 'Thumbs.db' \
    ! -path '*/images/*' \
    ! -path '*/fonts/*' \
    ! -path '*/videos/*' \
    ! -name '*.jpg' \
    ! -name '*.jpeg' \
    ! -name '*.png' \
    ! -name '*.gif' \
    ! -name '*.mp4' \
    ! -name '*.svg' \
    ! -name '*.ico' \
    | sort)

file_count=$(echo "$files" | wc -l)

# Add repository metadata to the buffer
buffer+="Repository:          $repo_url\n"
buffer+="Last Commit Date:    $last_commit_date\n"
buffer+="Last Commit Hash:    $last_commit_hash\n"
buffer+="Last Commit Message: $last_commit_message\n"
buffer+="=========================\n"

# Generate directory tree and add to the buffer
echo
echo "[AGGREGATE] Generating directory tree..."
buffer+="\nDirectory Tree:\n"
buffer+="$(tree -v -L 24 --charset utf-8)"
buffer+="\n"
if [ $? -eq 0 ]; then
    echo "[AGGREGATE] Directory tree added to the buffer."
else
    echo "[ERROR] Failed to generate directory tree."
    error_exit
fi

# Ensure README.md files are processed first
readmes=$(echo "$files" | grep -i '/README.md$')
files=$(echo "$files" | grep -vi '/README.md$')

# Process README.md files first
for readme in $readmes; do
    dump_file "$readme"
done

# Process the remaining files
for file in $files; do
    # Skip files to be excluded but allow .env.example
    if [[ "$file" == *"/.env.example" ]]; then
        dump_file "$file"
    elif [[ "$file" != *"/.env" && "$file" != *"-lock" && "$file" != *"/.github/*" ]]; then
        dump_file "$file"
    fi
done

# Process .github directory files last
github_files=$(find . -type f -path '*/.github/*' \
    ! -name '*.jpg' \
    ! -name '*.jpeg' \
    ! -name '*.png' \
    ! -name '*.gif' \
    ! -name '*.mp4' \
    ! -name '*.svg' \
    ! -name '*.ico' \
    | sort)
for github_file in $github_files; do
    dump_file "$github_file"
done

echo
echo "[WRITE] Writing the buffer to the output file..."
echo -e "$buffer" > "$output_file"
if [ $? -eq 0 ]; then
    echo "[WRITE] Buffer written to $output_file."
else
    echo "[ERROR] Failed to write the buffer to the output file."
    error_exit
fi

echo
echo "[COMPRESS] Compressing the output file..."
gzip -c "$output_file" > "$compressed_output_file" || error_exit
if [ $? -eq 0 ]; then
    echo "[COMPRESS] Output file compressed to $compressed_output_file."
else
    echo "[ERROR] Failed to compress the output file."
    error_exit
fi

echo
echo "[COMPLETE] Repository contents have been dumped into $output_file and compressed into $compressed_output_file."

# Explicitly call cleanup and exit successfully
success_exit

echo
echo "[CLEANUP] Temporary repository has been deleted."
