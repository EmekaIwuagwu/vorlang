# Contributing to Vorlang

We welcome contributions to the Vorlang programming language! This document outlines our contribution guidelines and development process.

## How to Contribute

1. **Fork the Repository**
   - Click the "Fork" button on GitHub
   - Clone your fork locally: `git clone https://github.com/your-username/vorlang.git`

2. **Set Up Development Environment**
   ```bash
   cd vorlang
   # Install dependencies (if any)
   # Set up build tools
   ```

3. **Create a Feature Branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```

4. **Write Code**
   - Follow our coding standards
   - Add tests for new functionality
   - Update documentation as needed

5. **Test Your Changes**
   ```bash
   # Run tests
   make test
   
   # Run linter/formatter
   make format
   ```

6. **Commit Changes**
   - Use conventional commit messages:
     - `feat: add new feature`
     - `fix: bug fix`
     - `docs: update documentation`
     - `test: add test cases`
     - `refactor: code refactoring`

7. **Push and Create Pull Request**
   ```bash
   git push origin feature/amazing-feature
   ```
   - Create a Pull Request on GitHub
   - Describe your changes clearly
   - Reference any related issues

## Development Guidelines

### Code Style
- Use meaningful variable and function names
- Follow existing code patterns
- Add comments for complex logic
- Keep functions focused and small

### Testing
- All new features must include tests
- Tests should cover edge cases
- Use descriptive test names
- Tests must pass before submitting PR

### Documentation
- Update relevant documentation for new features
- Add examples where appropriate
- Keep documentation accurate and up-to-date

## Project Structure

```
vorlang/
├── src/                    # Source code
│   ├── lexer/             # Lexical analysis
│   ├── parser/            # Syntax analysis
│   ├── semantic/          # Semantic analysis
│   ├── codegen/           # Code generation
│   └── vm/                # Virtual machine (if applicable)
├── tests/                 # Test files
├── docs/                  # Documentation
├── examples/              # Example programs
└── tools/                 # Development tools
```

## Building the Project

```bash
# Build the compiler
make build

# Run tests
make test

# Generate documentation
make docs

# Run linting
make lint
```

## Reporting Issues

When reporting bugs or requesting features:

1. **Search existing issues** first
2. **Provide clear reproduction steps**
3. **Include your environment details**:
   - OS version
   - Vorlang version
   - Relevant error messages
4. **Use labels appropriately** when creating issues

## Code of Conduct

We are committed to providing a welcoming and inclusive environment for all contributors. Please be respectful in all interactions and follow our code of conduct.

## Getting Help

- **Discussions**: Use GitHub Discussions for questions and community help
- **Issues**: Report bugs and feature requests on GitHub Issues
- **Documentation**: Check our docs first for answers
- **Community**: Join our Discord server for real-time help

## Review Process

1. **Automated Checks**: All PRs must pass CI/CD checks
2. **Code Review**: At least one maintainer must approve
3. **Testing**: All tests must pass
4. **Documentation**: Changes must be documented

## Becoming a Maintainer

Active contributors who consistently provide high-quality contributions may be invited to become maintainers. This includes:

- Regular code contributions
- Helping review PRs
- Answering community questions
- Improving documentation

## Questions?

If you have questions about contributing, please:
- Check the documentation
- Search existing issues
- Ask in GitHub Discussions
- Reach out to maintainers

Thank you for contributing to Vorlang! 🚀
