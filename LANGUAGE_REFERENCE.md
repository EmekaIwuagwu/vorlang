# Vorlang Language Reference

Complete language reference for Vorlang programming language.

## Table of Contents
1. [Lexical Structure](#lexical-structure)
2. [Types](#types)
3. [Expressions](#expressions)
4. [Statements](#statements)
5. [Functions](#functions)
6. [Modules](#modules)
7. [Standard Library](#standard-library)

## Lexical Structure

### Keywords
```
program begin end var const let
if then else elif endif
while do endwhile
for each in endfor
define function method class contract
module import as from export
return break continue
true false null
and or not is
```

### Operators
```
Arithmetic: + - * / % **
Comparison: == != < > <= >=
Logical: and or not
Assignment: = += -= *= /=
```

### Literals
```vorlang
42              // Integer
3.14            // Float
"hello"         // String
true, false     // Boolean
null            // Null
[1, 2, 3]       // List
{"key": "val"}  // Map
```

## Types

### Primitive Types

#### Integer
```vorlang
var count: Integer = 42
var negative = -10
```

#### Float
```vorlang
var price: Float = 19.99
var pi = 3.14159
```

#### String
```vorlang
var name: String = "Alice"
var message = "Hello, World!"
```

#### Boolean
```vorlang
var flag: Boolean = true
var active = false
```

#### Null
```vorlang
var empty = null
```

### Collection Types

#### List
```vorlang
var numbers: List = [1, 2, 3, 4, 5]
var mixed = [1, "two", 3.0, true]
var nested = [[1, 2], [3, 4]]
```

#### Map
```vorlang
var person: Map = {
    "name": "Alice",
    "age": 30,
    "active": true
}
```

#### Tuple (Limited Support)
```vorlang
var pair = (1, 2)
var triple = (1, "two", 3.0)
```

### Type Inference
```vorlang
var x = 42          // Inferred as Integer
var y = 3.14        // Inferred as Float
var z = "hello"     // Inferred as String
```

## Expressions

### Arithmetic
```vorlang
var sum = 10 + 20
var diff = 50 - 30
var product = 4 * 5
var quotient = 20 / 4
var remainder = 17 % 5
var power = 2 ** 8
```

### Comparison
```vorlang
var isEqual = (5 == 5)          // true
var notEqual = (5 != 3)         // true
var lessThan = (3 < 5)          // true
var greaterThan = (5 > 3)       // true
var lessOrEqual = (5 <= 5)      // true
var greaterOrEqual = (5 >= 3)   // true
```

### Logical
```vorlang
var both = true and false       // false
var either = true or false      // true
var opposite = not true         // false
```

### String Concatenation
```vorlang
var greeting = "Hello, " + "World!"
var message = "Count: " + str(42)
```

### List/Map Access
```vorlang
var list = [10, 20, 30]
var first = list[0]             // 10

var person = {"name": "Alice"}
var name = person["name"]       // "Alice"
```

## Statements

### Variable Declaration
```vorlang
var x = 10
var y: Integer = 20
var z: String = "hello"
```

### Constant Declaration
```vorlang
const PI = 3.14159
const MAX_SIZE = 100
```

### Assignment
```vorlang
x = 20
x += 5      // x = x + 5
x -= 3      // x = x - 3
x *= 2      // x = x * 2
x /= 4      // x = x / 4
```

### If Statement
```vorlang
if condition then
    // code
end if

if condition then
    // code
else
    // code
end if

if condition1 then
    // code
elif condition2 then
    // code
else
    // code
end if
```

### While Loop
```vorlang
while condition do
    // code
end while
```

### For-Each Loop
```vorlang
for each item in collection do
    // code
end for

// Alternative syntax
for item in collection do
    // code
end for
```

### Break and Continue
```vorlang
while true do
    if condition then
        break
    end if
    
    if otherCondition then
        continue
    end if
end while
```

### Return Statement
```vorlang
return value
return  // return null
```

## Functions

### Function Definition
```vorlang
define function name(param1: Type1, param2: Type2) : ReturnType
begin
    // code
    return value
end
```

### Examples
```vorlang
// No parameters, no return
define function sayHello()
begin
    IO.println("Hello!")
end

// With parameters, no return
define function greet(name: String)
begin
    IO.println("Hello, " + name + "!")
end

// With parameters and return
define function add(a: Integer, b: Integer) : Integer
begin
    return a + b
end

// Recursive function
define function factorial(n: Integer) : Integer
begin
    if n <= 1 then
        return 1
    else
        return n * factorial(n - 1)
    end if
end
```

## Modules

### Importing Modules
```vorlang
import io
import core
import string
import maths
```

### Using Module Functions
```vorlang
IO.println("Hello")
String.upper("hello")
Maths.sqrt(Sys.toFloat(16))
```

## Standard Library

### IO Module
```vorlang
import io

IO.println(message)     // Print with newline
```

### Core Module
```vorlang
import core

typeOf(value)           // Get type as string
str(value)              // Convert to string
Sys.toInt(value)        // Convert to integer
Sys.toFloat(value)      // Convert to float
Sys.toBool(value)       // Convert to boolean
```

### String Module
```vorlang
import string

String.length(str)              // Get length
String.slice(str, start, end)   // Substring
String.split(str, separator)    // Split into list
String.upper(str)               // To uppercase
String.lower(str)               // To lowercase
String.indexOf(str, substr)     // Find substring
```

### Maths Module
```vorlang
import maths

Maths.floor(x)          // Round down
Maths.ceil(x)           // Round up
Maths.sqrt(x)           // Square root
Maths.sin(x)            // Sine
Maths.cos(x)            // Cosine
Maths.random()          // Random 0-1
```

### Collections Module
```vorlang
import collections

List.length(list)           // Get length
List.append(list, item)     // Add item
Map.size(map)               // Get size
Map.keys(map)               // Get all keys
Collections.first(list)     // Get first item
```

### JSON Module
```vorlang
import json

JSON.stringify(data)    // Convert to JSON string
```

### Crypto Module
```vorlang
import crypto

Crypto.sha256(message)          // SHA-256 hash
Crypto.sha512(message)          // SHA-512 hash
Crypto.keccak256(message)       // Keccak-256 hash
Crypto.hmacSha256(data, key)    // HMAC-SHA256
Crypto.randomBytes(count)       // Random bytes
Crypto.hexEncode(bytes)         // Bytes to hex
```

### Blockchain Module
```vorlang
import blockchain

// Wallet operations
Blockchain.createWallet()
Blockchain.importWallet(privateKey)
Blockchain.getAddress(wallet)
Blockchain.signMessage(wallet, message)
Blockchain.isValidAddress(address)

// Transaction operations
Blockchain.createTransaction(sender, recipient, amount, nonce)
Blockchain.signTransaction(wallet, transaction)

// Block operations
Blockchain.createBlock(index, previousHash, transactions)
Blockchain.mineBlock(block, difficulty)
Blockchain.validateBlock(block, previousBlock)

// Blockchain operations
Blockchain.createBlockchain()
Blockchain.addBlock(chain, block)
Blockchain.getLatestBlock(chain)
Blockchain.validateChain(chain)
```

## Best Practices

### 1. Use Descriptive Names
```vorlang
// ❌ Bad
var x = 10
var y = 20

// ✅ Good
var userCount = 10
var maxRetries = 20
```

### 2. Add Comments
```vorlang
// Calculate the average score
var sum = 0
for each score in scores do
    sum = sum + score
end for
var average = sum / List.length(scores)
```

### 3. Check Before Accessing
```vorlang
// Check list bounds
if index >= 0 and index < List.length(list) then
    var item = list[index]
end if
```

### 4. Use Constants for Magic Numbers
```vorlang
const MAX_ATTEMPTS = 3
const TIMEOUT_SECONDS = 30
```

### 5. Break Down Complex Logic
```vorlang
// Instead of one complex function
// Break into smaller, focused functions
define function processUser(user: Map)
begin
    validateUser(user)
    saveUser(user)
    notifyUser(user)
end
```

---

**For more examples, see the `examples/` directory.**
