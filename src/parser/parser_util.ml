open Ast
open Lexer
open Parser

let parse_tokens tokens =
  let token_list = ref tokens in
  let next_token _ =
    match !token_list with
    | [] -> Parser.EOF
    | t :: ts ->
        token_list := ts;
        t
  in
  try
    Parser.program next_token (Lexing.from_string "")
  with
  | _ -> raise (Parse_error "Syntax error")

let parse_string s =
  let lexbuf = Lexing.from_string s in
  try
    Parser.program Lexer.token lexbuf
  with
  | Lexer.Lexing_error msg -> raise (Parse_error ("Lexing error: " ^ msg))
  | _ -> 
      let pos = lexbuf.Lexing.lex_curr_p in
      let msg = Printf.sprintf "Syntax error at line %d, col %d" 
                  pos.Lexing.pos_lnum (pos.Lexing.pos_cnum - pos.Lexing.pos_bol) in
      raise (Parse_error msg)

let parse_file filename =
  let ic = open_in filename in
  let lexbuf = Lexing.from_channel ic in
  lexbuf.Lexing.lex_curr_p <- { lexbuf.Lexing.lex_curr_p with Lexing.pos_fname = filename };
  try
    let result = Parser.program Lexer.token lexbuf in
    close_in ic;
    result
  with
  | Lexer.Lexing_error msg -> close_in ic; raise (Parse_error ("Lexing error: " ^ msg))
  | _ -> 
      let pos = lexbuf.Lexing.lex_curr_p in
      let msg = Printf.sprintf "Syntax error in %s at line %d, col %d" 
                  filename pos.Lexing.pos_lnum (pos.Lexing.pos_cnum - pos.Lexing.pos_bol) in
      close_in ic;
      raise (Parse_error msg)
