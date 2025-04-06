# replace_placeholder

A script to replace placeholders in an input file with values from a mapping file.
This is useful for configuration management in environments where secrets are injected at runtime.

## Usage

```sh
./replace_placeholder.posix.sh mapping_file input_file
```

- **mapping_file:** A file containing key-value pairs separated by `=` (e.g., `database_password=supersecret123`).
- **input_file:** A file containing placeholders in the format `<placeholder>key</placeholder>` that should be replaced by the corresponding value from the mapping file.

## File Formats

### Mapping File
Each line should have a key and a value separated by an equals sign (`=`). For example:

```text
database_password=supersecret123
api_key=abcdef123456
```

### Input File Placeholders
Placeholders should be wrapped with `<placeholder>` and `</placeholder>`. For example:

```text
The database password is: <placeholder>database_password</placeholder>
```

## Example

Given a mapping file `secrets.map`:

```text
database_password=supersecret123
api_key=abcdef123456
```

And an input file `config.txt`:

```text
DB_PASS=<placeholder>database_password</placeholder>
API_KEY=<placeholder>api_key</placeholder>
```

Running the script:

```sh
./replace_placeholder.posix.sh secrets.map config.txt
```

Will update `config.txt` to:

```text
DB_PASS=supersecret123
API_KEY=abcdef123456
```

## Version

Version: 1.0.0

## Contributing

Contributions, bug reports, and feature requests are welcome. Please open an issue or submit a pull request.

## License

This project is licensed under the GNU General Public License v3.0.
See the [LICENSE](LICENSE) file for more details.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
