# Vorlang Programming Language

Vorlang is a next-generation programming language designed to bridge the gap between readability and power. It combines English-like syntax with blockchain-native capabilities and modern systems programming features.

## Project Status

The Vorlang implementation currently includes:
- **Lexer & Parser**: Full support for programs, modules, functions, and structured control flow.
- **Semantic Analysis**: Type checking and symbol table management.
- **Bytecode Generator**: Translates Vorlang AST into a custom bytecode format.
- **Virtual Machine (VM)**: A stack-based interpreter that executes Vorlang bytecode with support for scoped variables, recursion, and complex data structures.
- **Networking Support**: Built-in support for real-time HTTP requests (via `curl` integration).

## Getting Started

### Prerequisites

To build the Vorlang compiler, you need:
- OCaml 4.12+
- `ocamlbuild`
- `ocamlfind`
- `menhir`
- `curl` (for networking features)

### Building the Compiler

Run the following commands in your terminal:

```bash
make clean
make
```

This will generate two executables:
- `vorlang.native`: The native-code compiler and VM runner.
- `vorlang.byte`: The bytecode-based version of the compiler.

### Running a Program

You can compile and execute a Vorlang program in one step using the `run` command:

```bash
./vorlang.native run examples/hello.vorlang
```

To see the generated Abstract Syntax Tree (AST) and Bytecode without running:

```bash
./vorlang.native compile examples/hello.vorlang
```

## Language Features

### Basic Syntax
```vorlang
program HelloWorld
begin
  print("Hello, Vorlang!")
end
```

### Real-Time Networking
Vorlang can perform real-world side effects like fetching your public IP:
```vorlang
import net

program GetIP
begin
    var url = "https://www.icanhazip.com/"
    print("Fetching IP from " + url + "...")
    
    var response = Net.get(url)
    var ip = response["body"]
    
    print("Your IP address is: " + str(ip))
end
```

### Recursion and Math
```vorlang
program Fibonacci
begin
  define function fibonacci(n: Integer) : Integer
  begin
    if n <= 1 then
      return n
    else
      return fibonacci(n - 1) + fibonacci(n - 2)
    end if
  end
  
  print("Fibonacci of 10 is: " + str(fibonacci(10)))
end
```

## Repository Structure

- `src/`: Compiler and VM source code (OCaml)
  - `lexer/`, `parser/`: Frontend implementation
  - `semantic/`: Type checking and analysis
  - `codegen/`: Bytecode generation
  - `vm/`: Bytecode interpreter (The Virtual Machine)
- `stdlib/`: Standard library definitions in Vorlang
- `examples/`: Sample programs demonstrating language features

## License

MIT License - see [LICENSE](LICENSE) for details.
"# vorlang" 
