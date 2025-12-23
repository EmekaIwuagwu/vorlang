open Parser



exception Lexing_error of string

(* Lexing function that takes a lexbuf and returns a token *)
val token : Lexing.lexbuf -> token

(* Helper function to create a lexer from a string *)
val from_string : string -> token list

(* Helper function to create a lexer from a file *)
val from_file : string -> token list

(* Print tokens for debugging *)
val print_tokens : token list -> unit
