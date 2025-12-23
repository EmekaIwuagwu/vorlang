(* Vorlang Lexer Tests *)
(* OCaml unit tests for the Vorlang lexer *)

open OUnit2
open Lexer
open Tokens

let test_lexer_tokens test_name input expected_tokens =
  test_name >:: (fun _ ->
    let tokens = from_string input in
    assert_equal expected_tokens tokens ~printer:(fun ts ->
      String.concat ", " (List.map token_to_string ts)
    )
  )

let lexer_tests = [
  test_lexer_tokens "simple program" "program Test begin end"
    [Keyword PROGRAM; Identifier "Test"; Keyword BEGIN; Keyword END; EOF];
  
  test_lexer_tokens "numbers" "42 3.14"
    [Integer 42; Float 3.14; EOF];
  
  test_lexer_tokens "strings" "\"hello\" \"world\""
    [String "hello"; String "world"; EOF];
  
  test_lexer_tokens "booleans" "true false"
    [Boolean true; Boolean false; EOF];
  
  test_lexer_tokens "operators" "+ - * / = == !="
    [Plus; Minus; Multiply; Divide; Assign; Equal; NotEqual; EOF];
  
  test_lexer_tokens "delimiters" "( ) { } [ ] , ; :"
    [LParen; RParen; LBrace; RBrace; LBracket; RBracket; Comma; Semicolon; Colon; EOF];
  
  test_lexer_tokens "comments" "var x = 5 // this is a comment"
    [Keyword VAR; Identifier "x"; Assign; Integer 5; EOF];
  
  test_lexer_tokens "multiline comments" "var x = 5 /* comment */ var y = 10"
    [Keyword VAR; Identifier "x"; Assign; Integer 5; Keyword VAR; Identifier "y"; Assign; Integer 10; EOF];
]

let suite = "Lexer Tests" >::: lexer_tests

let () =
  run_test_tt_main suite
