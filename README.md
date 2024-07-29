# Repository Dump Script

## Description

This script clones a specified GitHub repository into a temporary directory, aggregates the contents of all files (excluding specified files and directories) into a single `.txt` file, compresses the `.txt` file, and saves both the `.txt` and `.txt.gz` files in an output directory. Additionally, it generates a directory tree listing up to 24 levels deep and includes it in the `.txt` file. The script ensures that the temporary repository directory is cleaned up after execution.

## Features

- Clones a GitHub repository.
- Aggregates file contents into a single text file.
- Generates a directory tree listing and adds it to the text file.
- Compresses the text file using gzip.
- Cleans up the temporary repository directory after execution.

## Usage

### Prerequisites

- Ensure you have `git`, `tree`, and `gzip` installed on your system.
- The script is designed to run on Unix-like systems (Linux, macOS).

### Running the Script

1. Clone this repository or download the script file.
2. Open a terminal and navigate to the directory containing the script.
3. Make the script executable:
   ```sh
   chmod +x script.sh
   ```
4. Run the script by providing a GitHub repository URL:
   ```sh
   ./script.sh https://github.com/username/repository.git
   ```
   Alternatively, you can run the script without arguments and provide the URL when prompted.

### Example

```sh
./repository-dump.sh https://github.com/username/repository.git
```

### Output

- The script creates an output directory in the current working directory.
- The aggregated contents and directory tree are saved in a `.txt` file.
- The `.txt` file is compressed into a `.gz` file.

## Tests

Two tests were added to this project.

The first one, `test-script.sh`, will download `lodash/lodash`, which is a mid size repository.

```sh
./tests/test-script.sh
```

The first one, `test-script-stress.sh`, will download `facebook/react`, which is a large size repository.

```sh
./tests/test-script.sh
```

## Contributing

If you have suggestions for improving this script or find any issues, feel free to create an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
