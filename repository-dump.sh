#!/bin/bash

# Description:
# This script clones a specified GitHub repository into a temporary directory,
# aggregates the contents of all files (excluding specified files and directories) into a single .txt file,
# compresses the .txt file, and saves both the .txt and .txt.gz files in an output directory.
# It also generates a directory tree listing up to 24 levels deep and adds it to the .txt file.
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

# Check if a branch is provided, default to main/master
branch=${2:-main}

# Check if a directory or file is provided, default to root
path=${3:-.}

# Extract the repository name
repo_name=$(basename $repo_url .git)

# Define paths
script_dir=$(pwd)
output_dir="$script_dir/$repo_name-dump"
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
echo "[CLONE] Cloning repository $repo_url on branch $branch..."
git ls-remote --heads "$repo_url" "$branch" | grep -q "$branch"
if [ $? -ne 0 ]; then
    echo "[ERROR] The specified branch '$branch' does not exist in the repository."
    error_exit
fi

git clone --depth=1 --branch "$branch" "$repo_url" "$repo_path" || error_exit
echo "[CLONE] Repository cloned successfully."

# Check if the specified path exists
if [ ! -e "$repo_path/$path" ]; then
    echo "[ERROR] Specified path '$path' does not exist in the repository."
    error_exit
fi

# Process depending on whether the path is a directory or a file
if [ -d "$repo_path/$path" ]; then
    echo "[DEBUG] Path is a directory, processing contents..."
    cd "$repo_path/$path" || error_exit

    # Define the output file name
    output_file="$output_dir/${repo_name}_${branch}_${datetime}.txt"
    compressed_output_file="${output_file}.gz"

    # Buffer for aggregated content
    buffer="\n"

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
    echo "[DEBUG] Number of files found: $file_count"

    # Add repository metadata to the buffer
    buffer+="Repository:          $repo_url\n"
    buffer+="Branch:              $branch\n"
    buffer+="Directory:           $path\n"
    buffer+="=========================\n"

    # Generate directory tree and add to the buffer
    echo
    echo "[AGGREGATE] Generating directory tree..."
    tree_output=$(tree -v -L 24 --charset utf-8)
    if [ $? -eq 0 ]; then
        buffer+="$tree_output"
        buffer+="\n"
        echo "[AGGREGATE] Directory tree added to the buffer."
    else
        echo "[ERROR] Failed to generate directory tree."
        error_exit
    fi

    # Process all files in the directory
    for file in $files; do
        echo "[DEBUG] Processing file: $file"
        buffer+="\n=========================\n"
        buffer+="File: $file\n"
        buffer+="=========================\n"
        buffer+="$(cat "$file")"
    done

    echo "[DEBUG] Finished processing files, writing buffer to output file..."

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

else
    # If the path is a file, simply dump its contents
    echo "[DEBUG] Path is a file, dumping its contents..."

    output_file="$output_dir/${repo_name}_${branch}_${datetime}_$(basename "$path").txt"
    compressed_output_file="${output_file}.gz"

    echo
    echo "[WRITE] Writing the file to the output file..."
    echo "File: $path" > "$output_file"
    cat "$repo_path/$path" >> "$output_file"
    if [ $? -eq 0 ]; then
        echo "[WRITE] File written to $output_file."
    else
        echo "[ERROR] Failed to write the file to the output file."
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
fi

echo
echo "[COMPLETE] Repository contents have been dumped into $output_file and compressed into $compressed_output_file."

# Explicitly call cleanup and exit successfully
success_exit

echo
echo "[CLEANUP] Temporary repository has been deleted."
