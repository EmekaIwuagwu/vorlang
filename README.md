# 🛡️ Vorlang

**The Domain-Specific Language for High-Performance Blockchain and Backend Engineering.**

[![Tests](https://img.shields.io/badge/Tests-52%2F52%20Passed-brightgreen?style=for-the-badge&logo=github)](https://github.com/EmekaIwuagwu/vorlang)
[![Status](https://img.shields.io/badge/Version-v1.3.0--OOP-blue?style=for-the-badge)](https://github.com/EmekaIwuagwu/vorlang)
[![License](https://img.shields.io/badge/License-MIT-orange?style=for-the-badge)](LICENSE)

---

### 🚀 **December 2025 Milestone: 100% Test Pass Rate + PPA Available!**
Vorlang has reached a major milestone. As of **December 27, 2025**, the compiler achieves **52/52 tests passing** with full OOP method dispatch support and is now available via Ubuntu PPA!

**Current Dev Status:**
- ✅ **52/52 Tests Passing** - 100% success rate!
- ✅ **OOP Method Dispatch** - `obj.method()` syntax fully working!
- ✅ **Module Resolution Fixed** - IO, Collections, and custom modules all working
- ✅ **Ubuntu PPA Available** - Install with `sudo apt install vorlang`
- 🛠️ **Refactored Semantic Analyzer**: Inheritance-aware method lookup
- 📦 **Multiple Installers**: APT, curl script, PowerShell, and source build

---

## 🌟 Overview

Vorlang is a typed, expression-oriented systems language designed specifically for building decentralized applications, secure backend services, and robust command-line tools. Powered by a custom OCaml compiler and an optimized Virtual Machine, Vorlang blends the safety of functional programming with the approachability of imperative syntax.

### ✨ What's New (December 27, 2025)
- **OOP Method Dispatch**: Full `obj.method(args)` support with `this` binding
- **Class Methods**: Define methods that can access and modify instance fields
- **Inheritance Foundation**: Parent class method lookup infrastructure
- **Primitive Method Calls**: `list.length()`, `map.size()` style calls

---

## 💎 Features at a Glance

| Feature | Description | Status |
| :--- | :--- | :--- |
| **OOP Support** | Classes, methods, `this` binding, and method dispatch. | ✅ **New!** |
| **Blockchain First** | Native Block, Transaction, and Wallet types with automatic hashing. | ✅ Native |
| **Cryptography** | SHA-256, HMAC, RSA Sign/Verify, and AES-256 encryption. | ✅ Optimized |
| **Modern Syntax** | Expressive `if-else`, `while`, `foreach`, and Map/List literals. | ✅ Solid |
| **Strict Typing** | Semantic analysis layer ensures type safety before execution. | ✅ Verified |
| **Standard Library** | Comprehensive `Collections`, `Maths`, `IO`, `String`, `Env`, and `Time`. | ✅ Fully Coded |
| **High Speed** | Compiled to bytecode and executed via an OCaml-backed VM. | ✅ Fast |

---

## 🔗 Blockchain Example

Building a secure, signed transaction in Vorlang is second nature:

```vorlang
import blockchain
import crypto

define function createSecureTransfer(sender: Wallet, receiver: String, amount: Integer)
begin
    // Create transaction with native nonce and timestamp
    var tx = Blockchain.createTransaction(sender.address, receiver, amount, 0)
    
    // Sign the transaction using the sender's RSA private key
    var signedTx = Blockchain.signTransaction(sender, tx)
    
    print("Transaction Generated: " + signedTx.hash)
    return signedTx
end
```

---

## 🛠️ Installation & Setup

Vorlang provides production-ready installers for all major platforms.

### **Ubuntu/Debian (APT) - Recommended** 🆕

```bash
sudo add-apt-repository ppa:eiwuagwu/vorlang
sudo apt update
sudo apt install vorlang
```

### **One-Line Install (All Platforms)**

**Linux, macOS, or WSL:**
```bash
curl -fsSL https://raw.githubusercontent.com/EmekaIwuagwu/vorlang/main/install.sh | sudo bash
```

**Windows (PowerShell Admin):**
```powershell
iwr https://raw.githubusercontent.com/EmekaIwuagwu/vorlang/main/install.ps1 -useb | iex
```

---

### **Platform Specifics**

#### **Linux & macOS (Source Build)**
Ensure you have `make`, `ocaml`, and `openssl` installed.
```bash
git clone https://github.com/EmekaIwuagwu/vorlang
cd vorlang
sudo make install
```

#### **macOS (Homebrew)**
```bash
brew tap vorlang/tap
brew install vorlang
```

#### **Windows (Manual)**
1. Ensure `make` and `ocaml` are in your PATH.
2. Run `install.ps1` as Administrator.

---

### **Verification**
After installation, restart your terminal and run:
```bash
vorlangc --version
vorlang
```

---

## 📂 Project Structure

```text
vorlang/
├── src/                # Compiler Source (OCaml)
│   ├── ast/           # Abstract Syntax Tree
│   ├── parser/        # Menhir Parser definitions
│   ├── lexer/         # OCamllex Lexer
│   ├── semantic/      # Type checker & Semantic analyzer
│   ├── codegen/       # Bytecode generator
│   └── vm/            # The Vorlang Virtual Machine
├── stdlib/             # Standard Library (Vorlang-native)
├── examples/           # 51+ Verified test cases and examples
├── install.sh          # Linux/WSL Installer
├── install.ps1         # Windows PowerShell Installer
├── vorlangc            # Compiler Frontend Script
└── Makefile            # Build System
```

---

## 🧪 Testing Suite

Vorlang utilizes a rigorous testing framework to ensure compiler correctness and VM stability.

**Current Test Results:**
```text
Running tests...
----------------
Testing examples/banking_simple.vorlang... PASS
Testing examples/bc_test_multisig.vorlang... PASS
Testing examples/test_oop_methods.vorlang... PASS
Testing examples/test_modules.vorlang... PASS
Testing examples/test_foreach.vorlang... PASS
...
----------------
Passed: 52
Failed: 0
All tests passed! ✓
```

---

## 📜 Syntax Highlights

- **Modules**: Organize code with `module MyModule ... end module`.
- **Loops**: Support for `while` and the new `for each item in list` syntax.
- **Maps & Lists**: First-class support for `var m = {"key": "value"}` and `var l = [1, 2, 3]`.
- **Error Handling**: Use `panic("message")` for fatal errors or the `Errors` module for Result-type patterns.
- **Dynamic Calls**: Invoke functions by string name using `Sys.call(name, args)`.

---

## 📚 Learning Resources

- **Language Spec**: Check the `docs/` folder (coming soon).
- **Embedded Examples**: Read through `examples/blockchain_rpc_server.vorlang` to see high-level networking and logic.
- **StdLib Source**: The best way to learn is by reading `stdlib/core.vorlang`.

---

## 🤝 Contributing

We welcome scientists, cryptographers, and system engineers!
1. Fork the repo.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.

---

**Built with ❤️ by [Emeka Iwuagwu](https://github.com/EmekaIwuagwu) and the Vorlang Community.**
