# 🛡️ Vorlang

**The Domain-Specific Language for High-Performance Blockchain and Backend Engineering.**

[![Tests](https://img.shields.io/badge/Tests-51%2F51%20Passed-brightgreen?style=for-the-badge&logo=github)](https://github.com/EmekaIwuagwu/vorlang)
[![Status](https://img.shields.io/badge/Version-v1.0.0--Super-blue?style=for-the-badge)](https://github.com/EmekaIwuagwu/vorlang)
[![License](https://img.shields.io/badge/License-MIT-orange?style=for-the-badge)](LICENSE)

---

### 🚀 **December 2025 Milestone: 100% Stability Reached**
Vorlang has reached a critical maturity milestone. As of **December 26, 2025**, the local compiler environment has transitioned to the "Super" stable build following major refactors on Dec 25. 

**Current Dev Status:**
- ✅ **51/51 Tests Passing** (Core, StdLib, & Advanced Blockchain)
- 💎 **100% Success Rate** across all local examples.
- 🛠️ **Refactored VM**: High-performance JSON engine, Base64 support, and Cryptographic primitives.
- 📦 **Installer Ready**: Native deployment scripts for WSL, Linux, and Windows are now included in the root.

---

## 🌟 Overview

Vorlang is a typed, expression-oriented systems language designed specifically for building decentralized applications, secure backend services, and robust command-line tools. Powered by a custom OCaml compiler and an optimized Virtual Machine, Vorlang blends the safety of functional programming with the approachability of imperative syntax.

### ✨ What's New (December 2025)
- **Enhanced Test Suite**: Expanded from 37 to **51 comprehensive tests**.
- **Blockchain Maturity**: 14+ new advanced blockchain tests added, covering Bulk Transactions, Difficulty Adjustment, Fee Markets, Transaction History, Multisig Wallets, and Tamper-Resistance verification.
- **Security Standard Library**: Native support for JWT-style tokens, password hashing, and input sanitization.
- **Persistent Storage**: Integrated local K/V storage engine for state persistence.
- **Native JSON/Base64**: Recursive-descent JSON parser and Base64 encoding built directly into the VM for zero-dependency data handling.

---

## 💎 Features at a Glance

| Feature | Description | Status |
| :--- | :--- | :--- |
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

### **One-Line Install (Recommended)**

**Linux, macOS, or WSL:**
```bash
curl -fsSL https://get.vorlang.dev | bash
```

**Windows (PowerShell Admin):**
```powershell
iwr https://get.vorlang.dev/install.ps1 -useb | iex
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
Testing examples/bc_test_tamper.vorlang... PASS
Testing examples/test_storage_security.vorlang... PASS
...
----------------
Passed: 51
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
