# LanceDB Documentation

This repository contains the documentation for [LanceDB](https://github.com/lancedb/lancedb), a vector database for AI applications. The documentation is built using MkDocs and deployed to [lancedb.github.io/documentation](https://lancedb.github.io/documentation/).

## Building the Documentation Site

### Prerequisites

- Python 3.8 or higher
- Node.js and npm (for TypeScript examples)
- LanceDB Python package installed

### Setup

1. **Install LanceDB Python**:
   ```bash
   # From the LanceDB repository root
   cd python
   make develop
   ```

2. **Install documentation dependencies**:
   ```bash
   pip install -r docs/requirements.txt
   ```

### Building and Previewing

To preview the documentation locally with live reloading:

```bash
cd docs
mkdocs serve
```

The documentation will be available at [http://127.0.0.1:8000/](http://127.0.0.1:8000/).

To generate static HTML files:

```bash
PYTHONPATH=. mkdocs build -f docs/mkdocs.yml
```

This will create a `docs/site` directory with the built documentation, which you can open in a browser to verify locally.

## Contributing to LanceDB Documentation

### General Guidelines

1. **Clear and Concise**: Write documentation that is easy to understand.
2. **Examples**: Include practical examples where appropriate.
3. **Consistency**: Follow the existing documentation style and structure.
4. **Correctness**: Ensure all examples are tested and work correctly.

### Directory Structure

- `docs/src/` - Source markdown files for the documentation
- `docs/overrides/` - Custom template overrides for MkDocs
- `docs/test/` - Documentation tests

### Adding or Updating Documentation

1. Create or modify markdown files in the appropriate directory under `docs/src/`.
2. Add code examples in the relevant test directories to ensure they are verified by tests.
3. Preview your changes locally using `mkdocs serve`.
4. Submit a pull request with your changes.

### Testing Examples

Examples in the documentation are maintained as executable test files to ensure they remain correct.

#### Python Examples

Python examples are located in `python/python/tests/docs/`:

```bash
cd python
pytest -vv python/tests/docs
```

#### TypeScript Examples

TypeScript examples are in `nodejs/examples/`:

1. Build the LanceDB TypeScript package:
   ```bash
   cd nodejs
   npm ci
   npm run build
   ```

2. Run the examples:
   ```bash
   cd nodejs/examples
   npm ci
   npm test
   ```

### API Documentation

#### Python API

Python API documentation is organized based on `docs/src/python/python.md`. When adding new types or functions, they must be manually added to this file to appear in the reference documentation.

#### TypeScript API

TypeScript API documentation is generated using [typedoc](https://typedoc.org/). After adding new APIs, regenerate the documentation:

```bash
cd nodejs
npm run docs
```

The generated files should be committed to the repository.

## Deployment

The documentation is automatically built and deployed by GitHub Actions whenever a commit is pushed to the `main` branch. This means the documentation may include unreleased features.

## License

The documentation is licensed under the same license as LanceDB.
