(* Vorlang Abstract Syntax Tree *)
(* OCaml AST definitions for the Vorlang programming language *)

open Tokens

(* Type expressions *)
type type_expr =
  | TInteger
  | TFloat
  | TString
  | TBoolean
  | TNull
  | TList of type_expr
  | TMap of type_expr * type_expr
  | TSet of type_expr
  | TTuple of type_expr list
  | TFunction of type_expr list * type_expr
  | TIdentifier of string
  | TOptional of type_expr

(* Expressions *)
type expr =
  | Literal of literal
  | Identifier of string
  | BinaryOp of binary_op * expr * expr
  | UnaryOp of unary_op * expr
  | Assignment of expr * expr
  | FunctionCall of string * expr list
  | MemberAccess of expr * string
  | IndexAccess of expr * expr
  | ListLiteral of expr list
  | MapLiteral of (expr * expr) list
  | TupleLiteral of expr list
  | Lambda of string list * expr
  | Conditional of expr * expr * expr  (* if cond then true_expr else false_expr *)

and literal =
  | LInteger of int
  | LFloat of float
  | LString of string
  | LBoolean of bool
  | LNull

and binary_op =
  | Add | Sub | Mul | Div | Mod | Pow
  | Eq | Ne | Lt | Gt | Le | Ge
  | And | Or

and unary_op =
  | Neg | Not

(* Statements *)
type stmt =
  | ExprStmt of expr
  | VarDecl of string * type_expr option * expr option
  | ConstDecl of string * type_expr option * expr
  | AssignStmt of expr * expr
  | BlockStmt of stmt list
  | IfStmt of expr * stmt * stmt option
  | WhileStmt of expr * stmt
  | ForStmt of for_loop
  | FunctionDecl of function_def
  | ClassDecl of class_def
  | ContractDecl of contract_def
  | ModuleDecl of module_def
  | ReturnStmt of expr option
  | BreakStmt
  | ContinueStmt
  | TryStmt of stmt * (string * stmt) list * stmt option
  | ThrowStmt of expr
  | ImportStmt of import_spec
  | ExportStmt of export_spec

and for_loop =
  | ForEach of string * expr * stmt
  | ForRange of string * expr * expr * stmt

and function_def = {
  name : string;
  params : (string * type_expr * expr option) list;
  return_type : type_expr option;
  body : stmt list;
  is_async : bool;
}

and import_spec =
  | ImportAll of string
  | ImportFrom of string * string list
  | ImportAs of string * string

and export_spec =
  | ExportVar of string
  | ExportFunction of string
  | ExportAll

(* Program structure *)
and program = {
  name : string;
  imports : import_spec list;
  declarations : declaration list;
  body : stmt list;
}

and declaration =
  | DFunction of function_def
  | DClass of class_def
  | DContract of contract_def
  | DModule of module_def

and class_def = {
  name : string;
  fields : (string * type_expr * expr option) list;
  methods : function_def list;
  parent : string option;
}

and contract_def = {
  name : string;
  fields : (string * type_expr * expr option) list;
  methods : function_def list;
  events : event_def list;
}

and event_def = {
  name : string;
  params : (string * type_expr * expr option) list;
}

and module_def = {
  name : string;
  declarations : declaration list;
}

exception Parse_error of string

let expr_of_int n = Literal (LInteger n)

let rec string_of_type_expr = function
  | TInteger -> "Integer"
  | TFloat -> "Float"
  | TString -> "String"
  | TBoolean -> "Boolean"
  | TNull -> "Null"
  | TList t -> "List<" ^ string_of_type_expr t ^ ">"
  | TMap(k, v) -> "Map<" ^ string_of_type_expr k ^ ", " ^ string_of_type_expr v ^ ">"
  | TSet t -> "Set<" ^ string_of_type_expr t ^ ">"
  | TTuple ts -> "Tuple<" ^ String.concat ", " (List.map string_of_type_expr ts) ^ ">"
  | TFunction(args, ret) ->
      "Function<" ^ String.concat ", " (List.map string_of_type_expr args) ^ ", " ^
      string_of_type_expr ret ^ ">"
  | TIdentifier name -> name
  | TOptional t -> string_of_type_expr t ^ "?"

let rec print_expr indent expr =
  let prefix = String.make indent ' ' in
  match expr with
  | Literal lit ->
      let s = match lit with
        | LInteger n -> string_of_int n
        | LFloat f -> string_of_float f
        | LString s -> "\"" ^ s ^ "\""
        | LBoolean b -> string_of_bool b
        | LNull -> "null"
      in
      Printf.printf "%sLiteral: %s\n" prefix s
  | Identifier id -> Printf.printf "%sIdentifier: %s\n" prefix id
  | BinaryOp(op, l, r) ->
      Printf.printf "%sBinaryOp\n" prefix;
      print_expr (indent + 2) l;
      print_expr (indent + 2) r
  | UnaryOp(op, e) ->
      Printf.printf "%sUnaryOp\n" prefix;
      print_expr (indent + 2) e
  | Assignment(lhs, rhs) ->
      Printf.printf "%sAssignment\n" prefix;
      print_expr (indent + 2) lhs;
      print_expr (indent + 2) rhs
  | FunctionCall(name, args) ->
      Printf.printf "%sFunctionCall: %s\n" prefix name;
      List.iter (print_expr (indent + 2)) args
  | MemberAccess(e, m) ->
      Printf.printf "%sMemberAccess: %s\n" prefix m;
      print_expr (indent + 2) e
  | IndexAccess(e, idx) ->
      Printf.printf "%sIndexAccess\n" prefix;
      print_expr (indent + 2) e;
      print_expr (indent + 2) idx
  | ListLiteral es ->
      Printf.printf "%sListLiteral\n" prefix;
      List.iter (print_expr (indent + 2)) es
  | MapLiteral pairs ->
      Printf.printf "%sMapLiteral\n" prefix;
      List.iter (fun (k, v) -> print_expr (indent + 2) k; print_expr (indent + 2) v) pairs
  | TupleLiteral es ->
      Printf.printf "%sTupleLiteral\n" prefix;
      List.iter (print_expr (indent + 2)) es
  | Lambda(params, body) ->
      Printf.printf "%sLambda: (%s)\n" prefix (String.concat ", " params);
      print_expr (indent + 2) body
  | Conditional(c, t, f) ->
      Printf.printf "%sConditional\n" prefix;
      print_expr (indent + 2) c;
      print_expr (indent + 2) t;
      print_expr (indent + 2) f

let rec print_stmt indent stmt =
  let prefix = String.make indent ' ' in
  match stmt with
  | ExprStmt e ->
      Printf.printf "%sExprStmt\n" prefix;
      print_expr (indent + 2) e
  | VarDecl(name, typ, init) ->
      Printf.printf "%sVarDecl: %s\n" prefix name;
      (match init with Some e -> print_expr (indent + 2) e | None -> ())
  | ConstDecl(name, typ, value) ->
      Printf.printf "%sConstDecl: %s\n" prefix name;
      print_expr (indent + 2) value
  | AssignStmt(lhs, rhs) ->
      Printf.printf "%sAssignStmt\n" prefix;
      print_expr (indent + 2) lhs;
      print_expr (indent + 2) rhs
  | BlockStmt stmts ->
      Printf.printf "%sBlockStmt\n" prefix;
      List.iter (print_stmt (indent + 2)) stmts
  | IfStmt(c, t, e) ->
      Printf.printf "%sIfStmt\n" prefix;
      print_expr (indent + 2) c;
      print_stmt (indent + 2) t;
      (match e with Some s -> print_stmt (indent + 2) s | None -> ())
  | WhileStmt(c, b) ->
      Printf.printf "%sWhileStmt\n" prefix;
      print_expr (indent + 2) c;
      print_stmt (indent + 2) b
  | ForStmt loop ->
      Printf.printf "%sForStmt\n" prefix;
      (match loop with
       | ForEach(v, e, b) -> Printf.printf "%s  ForEach: %s\n" prefix v; print_expr (indent + 4) e; print_stmt (indent + 4) b
       | ForRange(v, s, e, b) -> Printf.printf "%s  ForRange: %s\n" prefix v; print_expr (indent + 4) s; print_expr (indent + 4) e; print_stmt (indent + 4) b)
  | FunctionDecl f -> Printf.printf "%sFunctionDecl: %s\n" prefix f.name
  | ClassDecl c -> Printf.printf "%sClassDecl: %s\n" prefix c.name
  | ContractDecl c -> Printf.printf "%sContractDecl: %s\n" prefix c.name
  | ModuleDecl m -> Printf.printf "%sModuleDecl: %s\n" prefix m.name
  | ReturnStmt e ->
      Printf.printf "%sReturnStmt\n" prefix;
      (match e with Some ex -> print_expr (indent + 2) ex | None -> ())
  | BreakStmt -> Printf.printf "%sBreakStmt\n" prefix
  | ContinueStmt -> Printf.printf "%sContinueStmt\n" prefix
  | TryStmt(b, c, f) -> Printf.printf "%sTryStmt\n" prefix
  | ThrowStmt e -> 
      Printf.printf "%sThrowStmt\n" prefix;
      print_expr (indent + 2) e
  | ImportStmt _ -> Printf.printf "%sImportStmt\n" prefix
  | ExportStmt _ -> Printf.printf "%sExportStmt\n" prefix

let print_program (program : program) =
  Printf.printf "Program: %s\n" program.name;
  Printf.printf "  Imports: %d\n" (List.length program.imports);
  List.iter (fun decl ->
    match decl with
    | DFunction f -> Printf.printf "  Function: %s\n" f.name; List.iter (print_stmt 4) f.body
    | DClass c -> Printf.printf "  Class: %s\n" c.name
    | DContract c -> Printf.printf "  Contract: %s\n" c.name
    | DModule m -> Printf.printf "  Module: %s\n" m.name
  ) program.declarations;
  Printf.printf "  Body:\n";
  List.iter (print_stmt 4) program.body
