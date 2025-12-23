(* Vorlang Full Compiler Tests *)
(* OCaml integration tests for the complete Vorlang compiler *)

open OUnit2
open Lexer
open Parser
open Semantic
open Codegen
open Ast
open Tokens
open Parser_util

let test_compilation test_name input expected_success =
  test_name >:: (fun _ ->
    try
      (* Test lexer *)
      let tokens = from_string input in
      assert_bool "Lexer should not return empty token list" (List.length tokens > 0);
      
      (* Test parser *)
      let program = parse_tokens tokens in
      assert_bool "Parser should return valid program" (program.declarations <> []);
      
      (* Test semantic analysis *)
      analyze_program program;
      
      (* Test code generation *)
      let bytecode = generate_program program in
      assert_bool "Code generation should produce instructions" (Array.length bytecode.instructions > 0);
      
      if not expected_success then
        assert_failure "Expected compilation to fail but it succeeded"
    with
    | Parse_error _ when expected_success ->
        assert_failure "Expected compilation to succeed but it failed"
    | Semantic_error _ when expected_success ->
        assert_failure "Expected compilation to succeed but it failed"
    | _ when not expected_success ->
        (* Expected failure, test passes *)
        ()
  )

let compilation_tests = [
  test_compilation "Hello World program" 
    "program HelloWorld begin print \"Hello, Vorlang!\" end"
    true;
  
  test_compilation "Simple function"
    "program Test begin define function add(a: Integer, b: Integer) : Integer begin return a + b end end"
    true;
  
  test_compilation "Variable declarations"
    "program Test begin var x = 42 var y : Integer = 100 const PI = 3.14 end"
    true;
  
  test_compilation "Control flow"
    "program Test begin if true then print \"yes\" else print \"no\" end if end"
    true;
  
  test_compilation "Loops"
    "program Test begin for i in 0..10 do print i end for end"
    true;
  
  test_compilation "Invalid syntax"
    "program Test begin invalid syntax here end"
    false;
  
  test_compilation "Type mismatch"
    "program Test begin var x : Integer = \"string\" end"
    false;
]

let suite = "Full Compiler Tests" >::: compilation_tests

let () =
  run_test_tt_main suite
