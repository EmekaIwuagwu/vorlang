(* Vorlang Token Definitions *)
(* This module is now primarily for compatibility and auxiliary token helpers. *)
(* Most token definitions have been moved to the Parser module. *)

(* Keeping keyword type for any remaining logic that might need it, 
   but it is largely superseded by Parser.token *)
type keyword =
  | PROGRAM | BEGIN | END | VAR | CONST | LET
  | IF | THEN | ELSE | END_IF | ELIF
  | WHILE | DO | END_WHILE | FOR | EACH | IN_KEYWORD | END_FOR
  | DEFINE | FUNCTION | PROCEDURE | METHOD | CLASS | CONTRACT
  | MODULE | END_MODULE | IMPORT | AS | FROM | EXPORT
  | RETURN | BREAK | CONTINUE | YIELD
  | TRY | CATCH | FINALLY | END_TRY | THROW
  | ASYNC | AWAIT | PROMISE
  | TRUE | FALSE | NULL | UNDEFINED
  | AND | OR | NOT | IS | IN
  | SELF | THIS | SUPER | NEW
  | EVENT | EMIT | DEPLOY | TO | BUILD | CHAIN | BASED | ON
  | CONSENSUS | CROSSCHAIN | CALL | WITH | OTHERWISE
  | MACRO | MATCH | CASE | WHEN
  | ALL | LIST | MAP | SET | TUPLE | EXTENDS
