# Vorlang Programming Language

<div align="center">

**A modern, blockchain-ready programming language with built-in cryptographic capabilities**

[![Tests](https://img.shields.io/badge/tests-37%2F37%20passing-brightgreen)]()
[![Stability](https://img.shields.io/badge/stability-production--ready-blue)]()
[![License](https://img.shields.io/badge/license-MIT-orange)]()

[Features](#features) • [Installation](#installation) • [Quick Start](#quick-start) • [Examples](#examples) • [Documentation](#documentation)

</div>

---

## 🎯 What is Vorlang?

Vorlang is a statically-typed, compiled programming language designed for:
- **Blockchain Development** - Built-in wallet, transaction, and mining capabilities
- **Cryptographic Operations** - Native SHA-256, Keccak-256, and HMAC support
- **Data Processing** - Powerful collections, JSON handling, and string manipulation
- **General Purpose Programming** - Clean syntax for algorithms, automation, and scripting

## ✨ Features

### Core Language
- ✅ **Strong Type System** - Integer, Float, String, Boolean, List, Map, Tuple
- ✅ **Control Flow** - if/elif/else, while loops, for-each loops
- ✅ **Functions** - First-class functions with type signatures
- ✅ **Recursion** - Full recursive function support
- ✅ **Module System** - Clean import/export mechanism
- ✅ **Pattern Matching** - (Coming soon)

### Standard Library (12 Modules)
- 📦 **Core** - Type checking, conversions, assertions
- 📝 **String** - Comprehensive string manipulation
- 🔢 **Maths** - Mathematical functions (sqrt, sin, cos, floor, ceil, random)
- 📊 **Collections** - List and Map utilities
- 🔐 **Crypto** - SHA-256, SHA-512, Keccak-256, HMAC, key generation
- ⛓️ **Blockchain** - Wallets, transactions, mining, chain validation
- 📄 **JSON** - Serialization and parsing
- 📁 **FS** - File system operations
- 🌐 **Net** - Network requests
- ⏰ **Time** - Date and time handling
- 📋 **Log** - Logging utilities
- 💾 **IO** - Input/output operations

### Blockchain Capabilities
```vorlang
import blockchain

program BlockchainDemo
begin
    // Create wallet
    var wallet = Blockchain.createWallet()
    IO.println("Address: " + wallet["address"])
    
    // Create blockchain
    var chain = Blockchain.createBlockchain()
    
    // Create and sign transaction
    var tx = Blockchain.createTransaction(wallet["address"], "recipient", 100, 0)
    var signedTx = Blockchain.signTransaction(wallet, tx)
    
    // Mine block
    var block = Blockchain.createBlock(1, "previous_hash", [signedTx])
    var minedBlock = Blockchain.mineBlock(block, 2)
    
    // Add to chain
    Blockchain.addBlock(chain, minedBlock)
    
    // Validate
    if Blockchain.validateChain(chain) then
        IO.println("✓ Blockchain is valid!")
    end if
end
```

## 🚀 Installation

### Prerequisites
- **OCaml** 4.12+ with ocamlbuild
- **Make**
- **OpenSSL** (for cryptographic operations)
- **Bash** (for running scripts)

### Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/vorlang.git
cd vorlang

# Build the compiler
make

# The compiler is now available as ./vorlangc
```

### Verify Installation

```bash
# Run all tests
bash run_tests.sh

# Should output: "Passed: 37, Failed: 0"
```

## 📖 Quick Start

### Hello World

Create `hello.vorlang`:
```vorlang
import io

program Hello
begin
    IO.println("Hello, World!")
end
```

Run it:
```bash
./vorlangc run hello.vorlang
```

### Your First Function

```vorlang
import io

program Fibonacci
begin
    define function fib(n: Integer) : Integer
    begin
        if n <= 1 then
            return n
        else
            return fib(n - 1) + fib(n - 2)
        end if
    end
    
    var i = 0
    while i <= 10 do
        IO.println("fib(" + str(i) + ") = " + str(fib(i)))
        i = i + 1
    end while
end
```

## 📚 Examples

The `examples/` directory contains 37 working examples:

### Basic Examples
- **hello.vorlang** - Hello World
- **calculator.vorlang** - Basic calculator
- **fibonacci.vorlang** - Fibonacci sequence

### Algorithms
- **bubble_sort.vorlang** - Bubble sort implementation
- **prime_sieve.vorlang** - Sieve of Eratosthenes
- **palindrome.vorlang** - Palindrome checker
- **factorial.vorlang** - Recursive factorial
- **matrix_mult.vorlang** - Matrix multiplication
- **tower_hanoi.vorlang** - Tower of Hanoi puzzle

### Data Processing
- **word_freq.vorlang** - Word frequency analysis
- **json_processor.vorlang** - JSON data processing
- **statistics.vorlang** - Statistical analysis

### Blockchain & Crypto
- **gen_blockchain.vorlang** - Blockchain generation
- **test_blockchain.vorlang** - Comprehensive blockchain test
- **hashing_demo.vorlang** - Cryptographic hashing

### Games & Interactive
- **guessing_game.vorlang** - Number guessing game
- **banking_simple.vorlang** - Banking system simulation

Run any example:
```bash
./vorlangc run examples/bubble_sort.vorlang
```

## 🔧 Compiler Usage

### Compile a File
```bash
./vorlangc compile myprogram.vorlang
```

### Run a File
```bash
./vorlangc run myprogram.vorlang
```

### Interactive REPL
```bash
./vorlangc repl
```

### Help
```bash
./vorlangc help
```

## 📝 Language Syntax

### Variables and Types
```vorlang
var name = "Alice"              // Type inference
var age: Integer = 30           // Explicit type
const PI = 3.14159             // Constant
```

### Control Flow
```vorlang
// If statement
if x > 0 then
    IO.println("Positive")
elif x < 0 then
    IO.println("Negative")
else
    IO.println("Zero")
end if

// While loop
while i < 10 do
    IO.println(str(i))
    i = i + 1
end while

// For-each loop
for each item in myList do
    IO.println(str(item))
end for
```

### Functions
```vorlang
define function add(a: Integer, b: Integer) : Integer
begin
    return a + b
end

define function greet(name: String)
begin
    IO.println("Hello, " + name + "!")
end
```

### Data Structures
```vorlang
// Lists
var numbers = [1, 2, 3, 4, 5]
var first = numbers[0]
List.append(numbers, 6)

// Maps
var person = {
    "name": "Alice",
    "age": 30,
    "active": true
}
var name = person["name"]
person["age"] = 31

// Nested structures
var users = [
    {"name": "Alice", "score": 100},
    {"name": "Bob", "score": 85}
]
```

### Modules
```vorlang
import io
import crypto
import blockchain

program MyApp
begin
    var hash = Crypto.sha256("Hello")
    IO.println("Hash: " + hash)
end
```

## 🧪 Testing

Run the full test suite:
```bash
bash run_tests.sh
```

Expected output:
```
Running tests...
----------------
Testing examples/banking_simple.vorlang... PASS
Testing examples/bubble_sort.vorlang... PASS
...
----------------
Passed: 37
Failed: 0
All tests passed!
```

## 🏗️ Project Structure

```
vorlang/
├── src/
│   ├── lexer/          # Tokenization
│   ├── parser/         # Syntax analysis
│   ├── ast/            # Abstract syntax tree
│   ├── semantic/       # Type checking
│   ├── codegen/        # Bytecode generation
│   ├── vm/             # Virtual machine
│   └── main.ml         # Compiler entry point
├── stdlib/             # Standard library modules
│   ├── blockchain.vorlang
│   ├── crypto.vorlang
│   ├── collections.vorlang
│   └── ...
├── examples/           # 37 example programs
├── tests/              # Additional tests
├── Documentation/      # Extended documentation
├── Makefile           # Build system
└── README.md          # This file
```

## 🎓 Learning Resources

- **Examples Directory** - 37 working examples covering all features
- **CHANGELOG.md** - Detailed version history
- **ROADMAP.md** - Future enhancements
- **Documentation/** - Extended guides and tutorials

## 🐛 Error Messages

Vorlang provides helpful error messages:

```
❌ Semantic Error
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
File: myprogram.vorlang
Error: Undefined identifier: x

💡 Tip: Check variable declarations and function signatures
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🤝 Contributing

Contributions are welcome! Areas for improvement:
- Full OOP support (method dispatch)
- Closures and lexical scoping
- Async/await implementation
- Additional standard library modules
- Performance optimizations

## 📜 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

Built with:
- OCaml compiler infrastructure
- Menhir parser generator
- OpenSSL for cryptography

## 📞 Support

- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Email**: support@vorlang.dev (example)

---

<div align="center">

**Made with ❤️ on Christmas Day 2025**

[⭐ Star on GitHub](https://github.com/yourusername/vorlang) • [📖 Documentation](./Documentation/) • [🐛 Report Bug](https://github.com/yourusername/vorlang/issues)

</div>
