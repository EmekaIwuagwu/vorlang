%{
  open Ast

  let split_stmts stmts =
    let rec aux decls bdy = function
      | [] -> (List.rev decls, List.rev bdy)
      | (Ast.FunctionDecl f) :: rest -> aux (Ast.DFunction f :: decls) bdy rest
      | (Ast.ClassDecl c) :: rest -> aux (Ast.DClass c :: decls) bdy rest
      | (Ast.ContractDecl c) :: rest -> aux (Ast.DContract c :: decls) bdy rest
      | (Ast.ModuleDecl m) :: rest -> aux (Ast.DModule m :: decls) bdy rest
      | s :: rest -> aux decls (s :: bdy) rest
    in aux [] [] stmts
  let rec flatten_member_access = function
    | Ast.Identifier id -> id
    | Ast.MemberAccess(e, id) -> flatten_member_access e ^ "." ^ id
    | _ -> failwith "not a member access"
%}

%token <string> IDENTIFIER
%token <int> INTEGER
%token <float> FLOAT
%token <string> STRING
%token <bool> BOOLEAN

%token PROGRAM BEGIN END VAR CONST LET
%token IF THEN ELSE ELIF WHILE DO FOR EACH IN EXTENDS
%token DEFINE FUNCTION PROCEDURE METHOD CLASS CONTRACT
%token MODULE IMPORT AS FROM EXPORT ALL
%token RETURN BREAK CONTINUE YIELD
%token TRY CATCH FINALLY THROW
%token ASYNC AWAIT PROMISE
%token TRUE FALSE NULL UNDEFINED
%token AND OR NOT IS
%token LIST MAP SET TUPLE
%token SELF THIS SUPER NEW
%token EVENT EMIT DEPLOY TO BUILD CHAIN BASED ON
%token CONSENSUS CROSSCHAIN CALL WITH OTHERWISE
%token MACRO MATCH CASE WHEN

%token ENDIF ENDWHILE ENDFOR ENDMODULE ENDFUNCTION ENDCLASS ENDCONTRACT ENDMETHOD ENDTRY

%token PLUS MINUS MULTIPLY DIVIDE MODULO POWER
%token EQUAL NOTEQUAL LESS GREATER LESSEQUAL GREATEREQUAL
%token ASSIGN PLUSASSIGN MINUSASSIGN MULTIPLYASSIGN DIVIDEASSIGN

%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET
%token COMMA COLON SEMICOLON DOT QUESTION

%token EOF

%left OR
%left AND
%left EQUAL NOTEQUAL
%left LESS GREATER LESSEQUAL GREATEREQUAL
%left PLUS MINUS
%left MULTIPLY DIVIDE MODULO
%right POWER
%right NOT
%left DOT LBRACKET LPAREN

%start program
%type <Ast.program> program

%%

program:
  | imports PROGRAM IDENTIFIER BEGIN stmt_list END EOF
    { let (decls, body) = split_stmts $5 in
      { name = $3; imports = $1; declarations = decls; body = body } }
  | imports MODULE IDENTIFIER stmt_list ENDMODULE EOF
    { let (decls, body) = split_stmts $4 in
      { name = $3; imports = $1; declarations = decls; body = body } }
  | imports MODULE IDENTIFIER stmt_list END EOF
    { let (decls, body) = split_stmts $4 in
      { name = $3; imports = $1; declarations = decls; body = body } }
;

imports:
  | /* empty */ { [] }
  | imports import_spec { $1 @ [$2] }
;

import_spec:
  | IMPORT IDENTIFIER { ImportAll $2 }
  | IMPORT IDENTIFIER AS IDENTIFIER { ImportAs($2, $4) }
  | IMPORT IDENTIFIER FROM IDENTIFIER { ImportFrom($4, [$2]) }
  | IMPORT LPAREN IDENTIFIER_LIST RPAREN FROM IDENTIFIER { ImportFrom($6, $3) }
;

IDENTIFIER_LIST:
  | IDENTIFIER { [$1] }
  | IDENTIFIER_LIST COMMA IDENTIFIER { $1 @ [$3] }
;

any_id:
  | IDENTIFIER { $1 }
  | MAP { "map" }
  | SET { "set" }
  | LIST { "list" }
  | EVENT { "event" }
  | TO { "to" }
  | BUILD { "build" }
  | CHAIN { "chain" }
  | CALL { "call" }
;

function_def:
  | DEFINE FUNCTION any_id LPAREN params RPAREN return_type BEGIN stmt_list END
    { { name = $3; params = $5; return_type = $7; body = $9; is_async = false } }
  | DEFINE ASYNC FUNCTION any_id LPAREN params RPAREN return_type BEGIN stmt_list END
    { { name = $4; params = $6; return_type = $8; body = $10; is_async = true } }
  | DEFINE FUNCTION any_id LPAREN params RPAREN return_type BEGIN stmt_list ENDFUNCTION
    { { name = $3; params = $5; return_type = $7; body = $9; is_async = false } }
;

params:
  | /* empty */ { [] }
  | param_list { $1 }
;

param_list:
  | param { [$1] }
  | param_list COMMA param { $1 @ [$3] }
;

param:
  | any_id COLON type_expr ASSIGN expr { ($1, $3, Some $5) }
  | any_id COLON type_expr { ($1, $3, None) }
  | any_id ASSIGN expr { ($1, TIdentifier "Any", Some $3) }
  | any_id { ($1, TIdentifier "Any", None) }
;

return_type:
  | /* empty */ { None }
  | COLON type_expr { Some $2 }
;

stmt_list:
  | /* empty */ { [] }
  | stmt_list stmt { $1 @ [$2] }
;

stmt:
  | var_decl { $1 }
  | const_decl { $1 }
  | assign_stmt { $1 }
  | if_stmt { $1 }
  | while_stmt { $1 }
  | for_stmt { $1 }
  | function_def { FunctionDecl $1 }
  | class_def { ClassDecl $1 }
  | contract_def { ContractDecl $1 }
  | module_def { ModuleDecl $1 }
  | return_stmt { $1 }
  | break_stmt { $1 }
  | continue_stmt { $1 }
  | try_stmt { $1 }
  | throw_stmt { $1 }
  | import_stmt { $1 }
  | export_stmt { $1 }
  | expr_stmt { $1 }
;

terminator:
  | SEMICOLON { () }
  | /* empty */ { () }
;

expr_stmt:
  | expr terminator { ExprStmt $1 }
;

var_decl:
  | VAR any_id COLON type_expr ASSIGN expr terminator
    { VarDecl($2, Some $4, Some $6) }
  | VAR any_id COLON type_expr terminator
    { VarDecl($2, Some $4, None) }
  | VAR any_id ASSIGN expr terminator
    { VarDecl($2, None, Some $4) }
  | VAR any_id terminator
    { VarDecl($2, None, None) }
;

const_decl:
  | CONST any_id COLON type_expr ASSIGN expr terminator
    { ConstDecl($2, Some $4, $6) }
  | CONST any_id ASSIGN expr terminator
    { ConstDecl($2, None, $4) }
;

assign_target:
  | postfix_expr { $1 }
;

assign_stmt:
  | assign_target ASSIGN expr terminator { AssignStmt($1, $3) }
  | assign_target PLUSASSIGN expr terminator { AssignStmt($1, BinaryOp(Add, $1, $3)) }
  | assign_target MINUSASSIGN expr terminator { AssignStmt($1, BinaryOp(Sub, $1, $3)) }
  | assign_target MULTIPLYASSIGN expr terminator { AssignStmt($1, BinaryOp(Mul, $1, $3)) }
  | assign_target DIVIDEASSIGN expr terminator { AssignStmt($1, BinaryOp(Div, $1, $3)) }
;

if_stmt:
  | IF expr THEN stmt_list ENDIF { IfStmt($2, BlockStmt $4, None) }
  | IF expr THEN stmt_list ELSE stmt_list ENDIF { IfStmt($2, BlockStmt $4, Some (BlockStmt $6)) }
  | IF expr THEN stmt_list elif_list ENDIF { IfStmt($2, BlockStmt $4, Some $5) }
;

elif_list:
  | ELIF expr THEN stmt_list { IfStmt($2, BlockStmt $4, None) }
  | ELIF expr THEN stmt_list elif_list { IfStmt($2, BlockStmt $4, Some $5) }
  | ELIF expr THEN stmt_list ELSE stmt_list { IfStmt($2, BlockStmt $4, Some (BlockStmt $6)) }
;

while_stmt:
  | WHILE expr DO stmt_list ENDWHILE { WhileStmt($2, BlockStmt $4) }
;

for_stmt:
  | FOR EACH IDENTIFIER IN expr DO stmt_list ENDFOR { ForStmt(ForEach($3, $5, BlockStmt $7)) }
  | FOR IDENTIFIER IN expr DO stmt_list ENDFOR { ForStmt(ForEach($2, $4, BlockStmt $6)) }
;

return_stmt:
  | RETURN expr terminator { ReturnStmt(Some $2) }
  | RETURN terminator { ReturnStmt(None) }
;

break_stmt:
  | BREAK terminator { BreakStmt }
;

continue_stmt:
  | CONTINUE terminator { ContinueStmt }
;

try_stmt:
  | TRY stmt_list catch_list finally ENDTRY { TryStmt(BlockStmt $2, $3, $4) }
;

catch_list:
  | /* empty */ { [] }
  | catch_item catch_list { $1 :: $2 }
;

catch_item:
  | CATCH IDENTIFIER stmt_list { ($2, BlockStmt $3) }
;

finally:
  | /* empty */ { None }
  | FINALLY stmt_list { Some (BlockStmt $2) }
;

throw_stmt:
  | THROW expr terminator { ThrowStmt $2 }
;

import_stmt:
  | import_spec { ImportStmt $1 }
;

export_stmt:
  | EXPORT any_id terminator { ExportStmt(ExportVar $2) }
  | EXPORT FUNCTION any_id terminator { ExportStmt(ExportFunction $3) }
  | EXPORT ALL terminator { ExportStmt(ExportAll) }
;

expr:
  | unary_expr { $1 }
  | expr PLUS expr { BinaryOp(Add, $1, $3) }
  | expr MINUS expr { BinaryOp(Sub, $1, $3) }
  | expr MULTIPLY expr { BinaryOp(Mul, $1, $3) }
  | expr DIVIDE expr { BinaryOp(Div, $1, $3) }
  | expr MODULO expr { BinaryOp(Mod, $1, $3) }
  | expr POWER expr { BinaryOp(Pow, $1, $3) }
  | expr EQUAL expr { BinaryOp(Eq, $1, $3) }
  | expr NOTEQUAL expr { BinaryOp(Ne, $1, $3) }
  | expr LESS expr { BinaryOp(Lt, $1, $3) }
  | expr GREATER expr { BinaryOp(Gt, $1, $3) }
  | expr LESSEQUAL expr { BinaryOp(Le, $1, $3) }
  | expr GREATEREQUAL expr { BinaryOp(Ge, $1, $3) }
  | expr AND expr { BinaryOp(And, $1, $3) }
  | expr OR expr { BinaryOp(Or, $1, $3) }
;

unary_expr:
  | postfix_expr { $1 }
  | NOT unary_expr { UnaryOp(Not, $2) }
  | MINUS unary_expr %prec NOT { UnaryOp(Neg, $2) }
;

postfix_expr:
  | primary_expr { $1 }
  | postfix_expr DOT any_id %prec DOT { MemberAccess($1, $3) }
  | postfix_expr LBRACKET expr RBRACKET %prec LBRACKET { IndexAccess($1, $3) }
  | postfix_expr LPAREN expr_list RPAREN %prec LPAREN { 
      try 
        let name = flatten_member_access $1 in
        FunctionCall(name, $3)
      with _ -> FunctionCall("DynamicCall", $3) 
    }
;

primary_expr:
  | literal { Literal $1 }
  | any_id { Identifier $1 }
  | LPAREN expr RPAREN { $2 }
  | LBRACKET expr_list RBRACKET { ListLiteral $2 }
  | LBRACE map_list RBRACE { MapLiteral $2 }
  | TUPLE LPAREN expr_list RPAREN { TupleLiteral $3 }
  | NEW any_id LPAREN expr_list RPAREN { New($2, $4) }
;

expr_list:
  | /* empty */ { [] }
  | expr { [$1] }
  | expr_list COMMA expr { $1 @ [$3] }
;

map_list:
  | /* empty */ { [] }
  | map_pair { [$1] }
  | map_list COMMA map_pair { $1 @ [$3] }
;

map_pair:
  | expr COLON expr { ($1, $3) }
;

literal:
  | INTEGER { LInteger $1 }
  | FLOAT { LFloat $1 }
  | STRING { LString $1 }
  | TRUE { LBoolean true }
  | FALSE { LBoolean false }
  | NULL { LNull }
;

type_expr:
  | any_id { TIdentifier $1 }
  | INTEGER { TInteger }
  | FLOAT { TFloat }
  | STRING { TString }
  | BOOLEAN { TBoolean }
  | NULL { TNull }
  | LIST LESS type_expr GREATER { TList $3 }
  | MAP LESS type_expr COMMA type_expr GREATER { TMap($3, $5) }
  | SET LESS type_expr GREATER { TSet $3 }
  | TUPLE LESS type_expr_list GREATER { TTuple $3 }
  | FUNCTION LESS type_expr_list GREATER { TFunction($3, TIdentifier "Any") }
  | type_expr QUESTION { TOptional $1 }
;

type_expr_list:
  | type_expr { [$1] }
  | type_expr_list COMMA type_expr { $1 @ [$3] }
;

class_def:
  | DEFINE CLASS any_id BEGIN class_body END
    { { name = $3; fields = (let f, m, e = $5 in f); methods = (let f, m, e = $5 in m); parent = None } }
  | DEFINE CLASS any_id BEGIN class_body ENDCLASS
    { { name = $3; fields = (let f, m, e = $5 in f); methods = (let f, m, e = $5 in m); parent = None } }
  | DEFINE CLASS any_id EXTENDS any_id BEGIN class_body END
    { { name = $3; fields = (let f, m, e = $7 in f); methods = (let f, m, e = $7 in m); parent = Some $5 } }
;

class_body:
  | /* empty */ { ([], [], []) }
  | class_body method_def { let f, m, e = $1 in (f, m @ [$2], e) }
  | class_body field_def { let f, m, e = $1 in (f @ [$2], m, e) }
;

method_def:
  | DEFINE METHOD any_id LPAREN params RPAREN return_type BEGIN stmt_list END
    { { name = $3; params = $5; return_type = $7; body = $9; is_async = false } }
  | DEFINE METHOD any_id LPAREN params RPAREN return_type BEGIN stmt_list ENDMETHOD
    { { name = $3; params = $5; return_type = $7; body = $9; is_async = false } }
;

field_def:
  | VAR any_id COLON type_expr terminator { ($2, $4, None) }
  | VAR any_id COLON type_expr ASSIGN expr terminator { ($2, $4, Some $6) }
;

contract_def:
  | DEFINE CONTRACT any_id BEGIN contract_body END
    { let f, m, e = $5 in { name = $3; fields = f; methods = m; events = e } }
  | DEFINE CONTRACT any_id BEGIN contract_body ENDCONTRACT
    { let f, m, e = $5 in { name = $3; fields = f; methods = m; events = e } }
;

contract_body:
  | /* empty */ { ([], [], []) }
  | contract_body method_def { let f, m, e = $1 in (f, m @ [$2], e) }
  | contract_body field_def { let f, m, e = $1 in (f @ [$2], m, e) }
  | contract_body event_def { let f, m, e = $1 in (f, m, e @ [$2]) }
;

event_def:
  | EVENT IDENTIFIER LPAREN params RPAREN terminator { { name = $2; params = $4 } }
;

module_def:
  | DEFINE MODULE any_id BEGIN stmt_list END
    { { name = $3; declarations = fst (split_stmts $5) } }
  | DEFINE MODULE any_id BEGIN stmt_list ENDMODULE
    { { name = $3; declarations = fst (split_stmts $5) } }
;
