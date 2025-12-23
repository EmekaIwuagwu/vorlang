# Vorlang Language Specification

## Overview

Vorlang is a next-generation programming language designed to bridge the gap between readability and power. It combines English-like syntax with blockchain-native capabilities, enabling developers to build everything from simple scripts to full blockchain ecosystems using a single, elegant language.

## 1. Lexical Structure

### 1.1 Keywords

Vorlang has the following reserved keywords:

```
program, begin, end, var, const, let
if, then, else, end if, elif
while, do, end while, for, each, in, end for
define, function, procedure, method, class, contract
module, end module, import, as, from, export
return, break, continue, yield
try, catch, finally, end try, throw
async, await, promise
true, false, null, undefined
and, or, not, is, in
self, this, super, new
event, emit, deploy, to, build, chain, based, on
consensus, crosschain, call, with, on
macro, emit, match, case, when, otherwise
```

### 1.2 Identifiers

Identifiers start with a letter or underscore, followed by letters, digits, or underscores:

```
identifier = [a-zA-Z_][a-zA-Z0-9_]*
```

Examples:
- `myVariable`
- `_privateVar`
- `CONSTANT_VALUE`

### 1.3 Literals

#### Integer Literals
```
42
-100
0
```

#### Float Literals
```
3.14
-2.5
1.0e-5
```

#### String Literals
```
"Hello, World!"
'Hello, World!'
```

#### Boolean Literals
```
true
false
```

#### Null Literal
```
null
```

### 1.4 Comments

#### Single-line Comments
```
// This is a comment
```

#### Multi-line Comments
```
/*
 * This is a
 * multi-line comment
 */
```

## 2. Type System

### 2.1 Primitive Types

- `Integer` - 64-bit signed integers
- `Float` - 64-bit floating-point numbers
- `String` - Unicode strings
- `Boolean` - Boolean values (`true`/`false`)
- `Null` - Null value

### 2.2 Collection Types

- `List<T>` - Ordered, mutable collections
- `Map<K, V>` - Key-value mappings
- `Set<T>` - Unique value collections
- `Tuple<T1, T2, ...>` - Fixed-size, immutable collections

### 2.3 Type Annotations

```vorlang
var count : Integer = 0
var name : String
var items : List<String>
var config : Map<String, Any>
```

## 3. Variables and Constants

### 3.1 Variable Declaration

```vorlang
var x = 42                    // Type inferred
var y : Integer = 100         // Explicit type
var z : String                // Uninitialized
```

### 3.2 Constant Declaration

```vorlang
const PI = 3.14159
const MAX_SIZE : Integer = 1000
```

### 3.3 Assignment

```vorlang
x = 10
x += 5        // x = x + 5
x -= 3        // x = x - 3
x *= 2        // x = x * 2
x /= 4        // x = x / 4
```

## 4. Control Flow

### 4.1 If Statements

```vorlang
if condition then
  // code
else if otherCondition then
  // code
else
  // code
end if
```

### 4.2 While Loops

```vorlang
while condition do
  // code
  if shouldBreak then break end if
  if shouldSkip then continue end if
end while
```

### 4.3 For Loops

```vorlang
// For-each
for each item in collection do
  print item
end for

// Range-based
for i in 0..10 do
  print i
end for

// With index
for each item, index in collection do
  print index + ": " + item
end for
```

## 5. Functions

### 5.1 Function Definition

```vorlang
define function add(a: Integer, b: Integer) : Integer
begin
  return a + b
end

// With default parameters
define function greet(name = "World", prefix = "Hello") : String
begin
  return prefix + " " + name + "!"
end

// Variable arguments
define function sum(numbers...)
begin
  var total = 0
  for each n in numbers do
    total = total + n
  end for
  return total
end
```

### 5.2 Anonymous Functions

```vorlang
var square = lambda(x) => x * x

var complexFunc = lambda(x, y)
begin
  var result = x * 2 + y
  return result
end
```

### 5.3 Async Functions

```vorlang
define async function fetchData(url: String) : String
begin
  var response = await httpGet(url)
  return response
end
```

## 6. Object-Oriented Programming

### 6.1 Class Definition

```vorlang
define class Person
begin
  var name : String
  var age : Integer
  var private ssn : String
  
  define method init(name: String, age: Integer, ssn = "")
  begin
    self.name = name
    self.age = age
    self.ssn = ssn
  end
  
  define method greet() : String
  begin
    return "Hello, I'm " + self.name
  end
  
  define static method fromBirthYear(name: String, birthYear: Integer) : Person
  begin
    var age = currentYear() - birthYear
    return new Person(name, age)
  end
end
```

### 6.2 Inheritance

```vorlang
define class Employee extends Person
begin
  var employeeId : String
  var salary : Float
  
  define method init(name: String, age: Integer, employeeId: String, salary: Float)
  begin
    super.init(name, age)
    self.employeeId = employeeId
    self.salary = salary
  end
  
  define override method greet() : String
  begin
    return super.greet() + ", ID: " + self.employeeId
  end
end
```

## 7. Modules

### 7.1 Module Definition

```vorlang
module Math
begin
  define function factorial(n: Integer) : Integer
  begin
    if n <= 1 then return 1 end if
    return n * factorial(n - 1)
  end
  
  define function fibonacci(n: Integer) : Integer
  begin
    if n <= 1 then return n end if
    return fibonacci(n - 1) + fibonacci(n - 2)
  end
  
  const PI = 3.14159265359
end module
```

### 7.2 Module Import

```vorlang
// Import entire module
import Math
begin
  print Math.factorial(5)
end

// Import specific items
from Math import factorial, PI
begin
  print factorial(5)
  print PI
end

// Import with alias
import Math as M
begin
  print M.factorial(5)
end
```

## 8. Smart Contracts

### 8.1 Contract Definition

```vorlang
define contract ERC20Token
begin
  var balances : Map<Address, Integer>
  var totalSupply : Integer
  var name : String
  var symbol : String
  
  event Transfer(from: Address, to: Address, amount: Integer)
  event Approval(owner: Address, spender: Address, amount: Integer)
  
  define method init(tokenName: String, tokenSymbol: String, initialSupply: Integer)
  begin
    name = tokenName
    symbol = tokenSymbol
    totalSupply = initialSupply
    balances[msg.sender] = initialSupply
  end
  
  define public method transfer(to: Address, amount: Integer) : Boolean
  begin
    require(balances[msg.sender] >= amount, "Insufficient balance")
    require(to != address(0), "Invalid recipient")
    
    balances[msg.sender] = balances[msg.sender] - amount
    balances[to] = balances[to] + amount
    
    emit Transfer(msg.sender, to, amount)
    return true
  end
  
  deploy to "EVM" with compiler "solc-0.8.20"
end
```

### 8.2 Built-in Blockchain Primitives

```vorlang
// Transaction context
msg.sender        // Current caller address
msg.value         // ETH/native token sent with call
msg.data          // Raw call data
block.number      // Current block number
block.timestamp   // Current block timestamp
tx.origin         // Original transaction sender

// Blockchain operations
require(condition, "Error message")   // Assert with revert
revert("Error message")               // Revert transaction
assert(condition)                     // Assert (uses all gas on failure)

// Address operations
address(0)                    // Zero address
this.balance                  // Contract balance
recipient.transfer(amount)    // Transfer native token
recipient.call(data)          // Low-level call

// Cryptographic functions
keccak256(data)              // Keccak-256 hash
sha256(data)                 // SHA-256 hash
ecrecover(hash, v, r, s)     // Recover signer address
```

## 9. Advanced Features

### 9.1 List Comprehensions

```vorlang
var numbers = list(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

// Basic comprehension
var evens = [x for x in numbers if x % 2 == 0]

// With transformation
var squares = [x * x for x in numbers]

// Multiple conditions
var filtered = [x for x in numbers if x > 3 and x < 8]

// Nested comprehension
var matrix = [[i * j for j in 1..5] for i in 1..5]
```

### 9.2 Destructuring

```vorlang
// List destructuring
var [first, second, ...rest] = list(1, 2, 3, 4, 5)

// Map destructuring
var {name, age, city = "Unknown"} = userData

// Function parameter destructuring
define function processUser({name, email})
begin
  print "Processing " + name + " (" + email + ")"
end
```

### 9.3 Generators

```vorlang
define function range(start: Integer, end: Integer)
begin
  var current = start
  while current < end do
    yield current
    current = current + 1
  end while
end

// Usage
for each n in range(0, 10) do
  print n
end for
```

### 9.4 Error Handling

```vorlang
try
  var data = readFile("config.json")
  var config = parseJSON(data)
catch FileNotFoundError as e
  print "Config file not found: " + e.message
catch ParseError as e
  print "Invalid JSON: " + e.message
finally
  print "Cleanup complete"
end try

// Custom errors
define class ValidationError extends Error
begin
  define method init(message: String)
  begin
    super.init(message)
  end
end

throw new ValidationError("Invalid input")
```

## 10. Compilation Targets

Vorlang supports multiple compilation targets:

- **Native**: Direct compilation to native machine code
- **WebAssembly**: Compilation to WASM for web and edge computing
- **EVM**: Ethereum Virtual Machine for Ethereum and EVM-compatible chains
- **CosmWasm**: Cosmos SDK smart contract platform
- **Solana**: Solana blockchain smart contracts
- **Move VM**: Aptos and Sui blockchain smart contracts

## 11. Grammar Summary

```
program: imports declarations EOF

imports: import_spec*

import_spec: 
  | IMPORT IDENTIFIER
  | IMPORT IDENTIFIER AS IDENTIFIER
  | IMPORT IDENTIFIER FROM IDENTIFIER

declarations: declaration*

declaration:
  | function_def
  | class_def
  | contract_def
  | module_def

function_def:
  | DEFINE FUNCTION IDENTIFIER LPAREN params RPAREN return_type BEGIN stmt_list END

stmt_list: stmt*

stmt:
  | expr_stmt
  | var_decl
  | const_decl
  | assign_stmt
  | if_stmt
  | while_stmt
  | for_stmt
  | function_def
  | return_stmt
  | break_stmt
  | continue_stmt
  | try_stmt
  | throw_stmt
  | import_stmt
  | export_stmt

expr:
  | literal
  | identifier
  | binary_op
  | unary_op
  | assignment
  | function_call
  | member_access
  | index_access
  | list_literal
  | map_literal
  | tuple_literal
  | lambda
  | conditional
```

## 12. Examples

### Hello World
```vorlang
program HelloWorld
begin
  print "Hello, Vorlang!"
end
```

### Fibonacci
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
  
  print fibonacci(10)
end
```

### Smart Contract
```vorlang
define contract SimpleToken
begin
  var balances : Map<Address, Integer>
  var totalSupply : Integer
  
  event Transfer(from: Address, to: Address, amount: Integer)
  
  define method init(initialSupply: Integer)
  begin
    totalSupply = initialSupply
    balances[msg.sender] = initialSupply
  end
  
  define public method transfer(to: Address, amount: Integer) : Boolean
  begin
    require(balances[msg.sender] >= amount, "Insufficient balance")
    balances[msg.sender] = balances[msg.sender] - amount
    balances[to] = balances[to] + amount
    emit Transfer(msg.sender, to, amount)
    return true
  end
  
  deploy to "EVM"
end
```

This specification provides a comprehensive overview of the Vorlang programming language syntax and features. For detailed implementation information, see the compiler source code and documentation.
