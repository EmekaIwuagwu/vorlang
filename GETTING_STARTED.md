# Getting Started with Vorlang

Welcome to Vorlang! This guide will help you write your first programs.

## Table of Contents
1. [Installation](#installation)
2. [Your First Program](#your-first-program)
3. [Basic Syntax](#basic-syntax)
4. [Working with Data](#working-with-data)
5. [Functions](#functions)
6. [Modules](#modules)
7. [Common Patterns](#common-patterns)
8. [Next Steps](#next-steps)

## Installation

### One-Line Install (Recommended)

**Linux, macOS, or WSL:**
```bash
curl -fsSL https://raw.githubusercontent.com/EmekaIwuagwu/vorlang/main/install.sh | bash
```

**Windows (PowerShell Admin):**
```powershell
iwr https://raw.githubusercontent.com/EmekaIwuagwu/vorlang/main/install.ps1 -useb | iex
```

### Manual Build

If you prefer building from source:

```bash
# Clone and build
git clone https://github.com/EmekaIwuagwu/vorlang.git
cd vorlang
make

# Install globally
sudo make install
```

### System Requirements
- OCaml 4.12+
- Make
- OpenSSL
- Bash

## Your First Program

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

Output:
```
Hello, World!
```

### Understanding the Structure

Every Vorlang program has:
1. **Imports** - Load standard library modules
2. **Program declaration** - Names your program
3. **Begin/End block** - Contains your code

```vorlang
import io          // 1. Import modules
import core

program MyApp      // 2. Program name
begin              // 3. Start of code
    // Your code here
end                // 3. End of code
```

## Basic Syntax

### Variables

```vorlang
// Type inference
var name = "Alice"
var age = 30
var score = 95.5
var active = true

// Explicit types
var count: Integer = 0
var price: Float = 19.99
var message: String = "Hello"
var flag: Boolean = false

// Constants
const PI = 3.14159
const MAX_USERS = 100
```

### Comments

```vorlang
// Single line comment

/*
   Multi-line comment
   (if supported)
*/
```

### Printing Output

```vorlang
import io

program PrintDemo
begin
    IO.println("Hello!")                    // Print with newline
    IO.println("Number: " + str(42))        // Convert to string
    IO.println("Sum: " + str(10 + 20))      // Expression in string
end
```

### Control Flow

#### If Statements

```vorlang
var x = 10

if x > 0 then
    IO.println("Positive")
elif x < 0 then
    IO.println("Negative")
else
    IO.println("Zero")
end if
```

#### While Loops

```vorlang
var i = 0
while i < 5 do
    IO.println(str(i))
    i = i + 1
end while
```

#### For-Each Loops

```vorlang
var numbers = [1, 2, 3, 4, 5]

for each num in numbers do
    IO.println(str(num))
end for
```

## Working with Data

### Lists

```vorlang
import io
import core

program ListDemo
begin
    // Create a list
    var fruits = ["apple", "banana", "cherry"]
    
    // Access elements
    IO.println(fruits[0])  // "apple"
    
    // Modify elements
    fruits[1] = "blueberry"
    
    // Add elements
    List.append(fruits, "date")
    
    // Get length
    var count = List.length(fruits)
    IO.println("Count: " + str(count))
    
    // Iterate
    for each fruit in fruits do
        IO.println("Fruit: " + fruit)
    end for
end
```

### Maps (Dictionaries)

```vorlang
import io

program MapDemo
begin
    // Create a map
    var person = {
        "name": "Alice",
        "age": 30,
        "city": "New York"
    }
    
    // Access values
    IO.println("Name: " + person["name"])
    
    // Modify values
    person["age"] = 31
    
    // Add new keys
    person["country"] = "USA"
    
    // Get all keys
    var keys = Map.keys(person)
    for each key in keys do
        IO.println(key + ": " + str(person[key]))
    end for
end
```

### Nested Structures

```vorlang
var users = [
    {"name": "Alice", "score": 100},
    {"name": "Bob", "score": 85},
    {"name": "Charlie", "score": 92}
]

for each user in users do
    IO.println(user["name"] + ": " + str(user["score"]))
end for
```

## Functions

### Basic Functions

```vorlang
import io

program FunctionDemo
begin
    // Function with return value
    define function add(a: Integer, b: Integer) : Integer
    begin
        return a + b
    end
    
    // Function without return value
    define function greet(name: String)
    begin
        IO.println("Hello, " + name + "!")
    end
    
    // Call functions
    var sum = add(5, 3)
    IO.println("Sum: " + str(sum))
    
    greet("Alice")
end
```

### Recursive Functions

```vorlang
define function factorial(n: Integer) : Integer
begin
    if n <= 1 then
        return 1
    else
        return n * factorial(n - 1)
    end if
end

var result = factorial(5)
IO.println("5! = " + str(result))  // 120
```

## Modules

### Using Standard Library

```vorlang
import io
import string
import maths
import json

program ModuleDemo
begin
    // String operations
    var text = "hello world"
    var upper = String.upper(text)
    IO.println(upper)  // "HELLO WORLD"
    
    // Math operations
    var root = Maths.sqrt(Sys.toFloat(16))
    IO.println("√16 = " + str(root))
    
    // JSON
    var data = {"name": "Alice", "age": 30}
    var jsonStr = JSON.stringify(data)
    IO.println(jsonStr)
end
```

### Available Modules

- **io** - Input/output
- **core** - Type checking, conversions
- **string** - String manipulation
- **maths** - Mathematical functions
- **collections** - List/Map utilities
- **json** - JSON serialization
- **crypto** - Cryptographic functions
- **blockchain** - Blockchain operations
- **fs** - File system
- **time** - Date and time
- **net** - Network operations

## Common Patterns

### Reading and Processing Data

```vorlang
import io
import string

program DataProcessing
begin
    var text = "apple,banana,cherry,date"
    var items = String.split(text, ",")
    
    for each item in items do
        IO.println("Item: " + item)
    end for
end
```

### Counting and Aggregating

```vorlang
var numbers = [10, 20, 30, 40, 50]
var sum = 0
var count = 0

for each num in numbers do
    sum = sum + num
    count = count + 1
end for

var average = sum / count
IO.println("Average: " + str(average))
```

### Filtering Data

```vorlang
var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
var evens = []

for each num in numbers do
    if (num % 2) == 0 then
        List.append(evens, num)
    end if
end for

// evens now contains [2, 4, 6, 8, 10]
```

### Error Handling Pattern

```vorlang
// Check before accessing
if Map.size(myMap) > 0 then
    // Safe to access
    var value = myMap["key"]
end if

// Validate input
if age >= 0 and age <= 150 then
    // Valid age
else
    IO.println("Invalid age!")
end if
```

## Next Steps

### 1. Explore Examples
Check out the `examples/` directory for **51** working programs:
```bash
vorlangc run examples/bubble_sort.vorlang
vorlangc run examples/blockchain_demo.vorlang
vorlangc run examples/statistics.vorlang
```

### 2. Try Blockchain Features
```vorlang
import blockchain
import io

program BlockchainStart
begin
    var wallet = Blockchain.createWallet()
    IO.println("Your address: " + wallet["address"])
    
    var chain = Blockchain.createBlockchain()
    IO.println("Blockchain created!")
end
```

### 3. Experiment with Crypto
```vorlang
import crypto
import io

program CryptoStart
begin
    var message = "Hello, Vorlang!"
    var hash = Crypto.sha256(message)
    IO.println("SHA-256: " + hash)
end
```

### 4. Build Something
Ideas for practice:
- Todo list manager
- Grade calculator
- Text analyzer
- Simple game
- Data processor

### 5. Read the Documentation
- `README.md` - Complete reference
- `ROADMAP.md` - Future features
- `CHANGELOG.md` - Version history
- `examples/` - Working code

## Tips and Tricks

### 1. Type Conversion
```vorlang
var num = 42
var text = str(num)           // Integer to String
var float = Sys.toFloat(num)  // Integer to Float
var int = Sys.toInt(text)     // String to Integer
```

### 2. String Concatenation
```vorlang
var name = "Alice"
var age = 30
var message = "Name: " + name + ", Age: " + str(age)
```

### 3. List Operations
```vorlang
var list = [1, 2, 3]
var length = List.length(list)
List.append(list, 4)
var first = list[0]
```

### 4. Debugging
```vorlang
// Print variable values
IO.println("Debug: x = " + str(x))

// Check types
var t = typeOf(myVar)
IO.println("Type: " + t)
```

## Common Errors and Solutions

### Error: "Undefined identifier"
**Problem**: Variable not declared
```vorlang
// ❌ Wrong
IO.println(x)

// ✅ Correct
var x = 10
IO.println(str(x))
```

### Error: "Type mismatch"
**Problem**: Wrong type in operation
```vorlang
// ❌ Wrong
var result = "5" + 3

// ✅ Correct
var result = Sys.toInt("5") + 3
```

### Error: "Index out of bounds"
**Problem**: Accessing invalid array index
```vorlang
// ❌ Wrong
var list = [1, 2, 3]
var x = list[10]

// ✅ Correct
if 10 < List.length(list) then
    var x = list[10]
end if
```

## Getting Help

- Check `examples/` for working code
- Read error messages carefully
- Use `IO.println()` for debugging
- Review the README.md
- Test small pieces of code first

---

**Happy Coding with Vorlang! 🚀**
