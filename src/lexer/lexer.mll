{ 
  open Parser

  exception Lexing_error of string

  let newline lexbuf =
    let pos = lexbuf.Lexing.lex_curr_p in
    lexbuf.Lexing.lex_curr_p <-
      { pos with
        Lexing.pos_lnum = pos.Lexing.pos_lnum + 1;
        Lexing.pos_bol = pos.Lexing.pos_cnum;
      }

  let token_error msg lexbuf =
    let pos = lexbuf.Lexing.lex_curr_p in
    let line = pos.Lexing.pos_lnum in
    let col = pos.Lexing.pos_cnum - pos.Lexing.pos_bol in
    raise (Lexing_error (Printf.sprintf "Line %d, Column %d: %s" line col msg))

  let keyword_of_string = function
    | "program" -> PROGRAM
    | "begin" -> BEGIN
    | "end" -> END
    | "var" -> VAR
    | "const" -> CONST
    | "let" -> LET
    | "if" -> IF
    | "then" -> THEN
    | "else" -> ELSE
    | "elif" -> ELIF
    | "while" -> WHILE
    | "do" -> DO
    | "for" -> FOR
    | "each" -> EACH
    | "in" -> IN
    | "extends" -> EXTENDS
    | "define" -> DEFINE
    | "function" -> FUNCTION
    | "procedure" -> PROCEDURE
    | "method" -> METHOD
    | "class" -> CLASS
    | "contract" -> CONTRACT
    | "module" -> MODULE
    | "import" -> IMPORT
    | "as" -> AS
    | "from" -> FROM
    | "export" -> EXPORT
    | "all" -> ALL
    | "return" -> RETURN
    | "break" -> BREAK
    | "continue" -> CONTINUE
    | "yield" -> YIELD
    | "try" -> TRY
    | "catch" -> CATCH
    | "finally" -> FINALLY
    | "throw" -> THROW
    | "async" -> ASYNC
    | "await" -> AWAIT
    | "promise" -> PROMISE
    | "true" -> TRUE
    | "false" -> FALSE
    | "null" -> NULL
    | "undefined" -> UNDEFINED
    | "and" -> AND
    | "or" -> OR
    | "not" -> NOT
    | "is" -> IS
    | "list" -> LIST
    | "map" -> MAP
    | "set" -> SET
    | "tuple" -> TUPLE
    | "self" -> SELF
    | "this" -> THIS
    | "super" -> SUPER
    | "new" -> NEW
    | "event" -> EVENT
    | "emit" -> EMIT
    | "deploy" -> DEPLOY
    | "to" -> TO
    | "build" -> BUILD
    | "chain" -> CHAIN
    | "based" -> BASED
    | "on" -> ON
    | "consensus" -> CONSENSUS
    | "crosschain" -> CROSSCHAIN
    | "call" -> CALL
    | "with" -> WITH
    | "otherwise" -> OTHERWISE
    | "macro" -> MACRO
    | "match" -> MATCH
    | "case" -> CASE
    | "when" -> WHEN
    | _ -> raise Not_found
}

let digit = ['0'-'9']
let letter = ['a'-'z' 'A'-'Z']
let id_start = letter | '_'
let id_char = letter | digit | '_'
let identifier = id_start id_char*

let whitespace = [' ' '\t' '\r']
let newline = '\n' | '\r' '\n'

let integer = '-'? digit+
let float = '-'? digit+ '.' digit+
let string = '"' (('\\' _) | [^ '"' '\\' '\n'])* '"'

rule token = parse
  | whitespace { token lexbuf }
  | newline { newline lexbuf; token lexbuf }
  
  (* Comments *)
  | "//" [^ '\n']* { token lexbuf }
  | "/*" { comment lexbuf; token lexbuf }
  
  (* Composite Keywords *)
  | "else" whitespace+ "if" { ELIF }
  | "end" whitespace+ "if" { ENDIF }
  | "end" whitespace+ "while" { ENDWHILE }
  | "end" whitespace+ "for" { ENDFOR }
  | "end" whitespace+ "module" { ENDMODULE }
  | "end" whitespace+ "function" { ENDFUNCTION }
  | "end" whitespace+ "class" { ENDCLASS }
  | "end" whitespace+ "contract" { ENDCONTRACT }
  | "end" whitespace+ "method" { ENDMETHOD }
  | "end" whitespace+ "try" { ENDTRY }

  (* Keywords and identifiers *)
  | identifier as id {
      try keyword_of_string id
      with Not_found -> IDENTIFIER id
    }
  
  (* Literals *)
  | integer as n { INTEGER (int_of_string n) }
  | float as f { FLOAT (float_of_string f) }
  | string as s { STRING (String.sub s 1 (String.length s - 2)) }
  
  (* Operators *)
  | "+" { PLUS }
  | "-" { MINUS }
  | "*" { MULTIPLY }
  | "/" { DIVIDE }
  | "%" { MODULO }
  | "**" { POWER }
  | "=" { ASSIGN }
  | "+=" { PLUSASSIGN }
  | "-=" { MINUSASSIGN }
  | "*=" { MULTIPLYASSIGN }
  | "/=" { DIVIDEASSIGN }
  | "==" { EQUAL }
  | "!=" { NOTEQUAL }
  | "<" { LESS }
  | ">" { GREATER }
  | "<=" { LESSEQUAL }
  | ">=" { GREATEREQUAL }
  
  (* Delimiters *)
  | "(" { LPAREN }
  | ")" { RPAREN }
  | "{" { LBRACE }
  | "}" { RBRACE }
  | "[" { LBRACKET }
  | "]" { RBRACKET }
  | "," { COMMA }
  | ":" { COLON }
  | ";" { SEMICOLON }
  | "." { DOT }
  | "?" { QUESTION }
  
  (* End of file *)
  | eof { EOF }
  
  (* Error handling *)
  | _ as c { token_error (Printf.sprintf "Unexpected character: %c" c) lexbuf }

and comment = parse
  | "*/" { () }
  | '\n' { newline lexbuf; comment lexbuf }
  | eof { token_error "Unterminated comment" lexbuf }
  | _ { comment lexbuf }

{
  let token_to_string = function
    | IDENTIFIER s -> "IDENTIFIER(" ^ s ^ ")"
    | INTEGER n -> "INTEGER(" ^ string_of_int n ^ ")"
    | FLOAT f -> "FLOAT(" ^ string_of_float f ^ ")"
    | STRING s -> "STRING(" ^ s ^ ")"
    | BOOLEAN b -> "BOOLEAN(" ^ string_of_bool b ^ ")"
    | PROGRAM -> "program" | BEGIN -> "begin" | END -> "end"
    | VAR -> "var" | CONST -> "const" | LET -> "let"
    | IF -> "if" | THEN -> "then" | ELSE -> "else" | ELIF -> "elif"
    | WHILE -> "while" | DO -> "do" | FOR -> "for" | EACH -> "each" | IN -> "in"
    | EXTENDS -> "extends" | DEFINE -> "define" | FUNCTION -> "function"
    | PROCEDURE -> "procedure" | METHOD -> "method" | CLASS -> "class" | CONTRACT -> "contract"
    | MODULE -> "module" | IMPORT -> "import" | AS -> "as" | FROM -> "from" | EXPORT -> "export" | ALL -> "all"
    | RETURN -> "return" | BREAK -> "break" | CONTINUE -> "continue" | YIELD -> "yield"
    | TRY -> "try" | CATCH -> "catch" | FINALLY -> "finally" | THROW -> "throw"
    | ASYNC -> "async" | AWAIT -> "await" | PROMISE -> "promise"
    | TRUE -> "true" | FALSE -> "false" | NULL -> "null" | UNDEFINED -> "undefined"
    | AND -> "and" | OR -> "or" | NOT -> "not" | IS -> "is"
    | LIST -> "list" | MAP -> "map" | SET -> "set" | TUPLE -> "tuple"
    | SELF -> "self" | THIS -> "this" | SUPER -> "super" | NEW -> "new"
    | EVENT -> "event" | EMIT -> "emit" | DEPLOY -> "deploy" | TO -> "to" | BUILD -> "build" | CHAIN -> "chain" | BASED -> "based" | ON -> "on"
    | CONSENSUS -> "consensus" | CROSSCHAIN -> "crosschain" | CALL -> "call" | WITH -> "with" | OTHERWISE -> "otherwise"
    | MACRO -> "macro" | MATCH -> "match" | CASE -> "case" | WHEN -> "when"
    | PLUS -> "+" | MINUS -> "-" | MULTIPLY -> "*" | DIVIDE -> "/" | MODULO -> "%" | POWER -> "**"
    | EQUAL -> "==" | NOTEQUAL -> "!=" | LESS -> "<" | GREATER -> ">" | LESSEQUAL -> "<=" | GREATEREQUAL -> ">="
    | ASSIGN -> "=" | PLUSASSIGN -> "+=" | MINUSASSIGN -> "-=" | MULTIPLYASSIGN -> "*=" | DIVIDEASSIGN -> "/="
    | LPAREN -> "(" | RPAREN -> ")" | LBRACE -> "{" | RBRACE -> "}" | LBRACKET -> "[" | RBRACKET -> "]"
    | COMMA -> "," | COLON -> ":" | SEMICOLON -> ";" | DOT -> "." | QUESTION -> "?"
    | ENDIF -> "endif" | ENDWHILE -> "endwhile" | ENDFOR -> "endfor" 
    | ENDMODULE -> "endmodule" | ENDFUNCTION -> "endfunction" | ENDCLASS -> "endclass" 
    | ENDCONTRACT -> "endcontract" | ENDMETHOD -> "endmethod" | ENDTRY -> "endtry"
    | EOF -> "EOF"

  let from_string s =
    let lexbuf = Lexing.from_string s in
    let rec loop acc =
      let t = token lexbuf in
      if t = Parser.EOF then List.rev (t :: acc)
      else loop (t :: acc)
    in
    loop []

  let from_file filename =
    let ic = open_in filename in
    let lexbuf = Lexing.from_channel ic in
    lexbuf.Lexing.lex_curr_p <- { lexbuf.Lexing.lex_curr_p with Lexing.pos_fname = filename };
    let rec loop acc =
      let t = token lexbuf in
      if t = Parser.EOF then (close_in ic; List.rev (t :: acc))
      else loop (t :: acc)
    in
    loop []

  let print_tokens tokens =
    List.iter (fun t -> Printf.printf "%s " (token_to_string t)) tokens;
    Printf.printf "\n"
}
