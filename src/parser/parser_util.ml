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

let rec prefix_calls_in_expr prefix names expr =
  let p = prefix_calls_in_expr prefix names in
  match expr with
  | Literal _ -> expr
  | Identifier id -> if List.mem id names then Identifier (prefix ^ "." ^ id) else expr
  | BinaryOp(op, l, r) -> BinaryOp(op, p l, p r)
  | UnaryOp(op, e) -> UnaryOp(op, p e)
  | Assignment(l, r) -> Assignment(p l, p r)
  | FunctionCall(name, args) ->
      let new_name = if List.mem name names then prefix ^ "." ^ name else name in
      FunctionCall(new_name, List.map p args)
  | MemberAccess(e, m) -> MemberAccess(p e, m)
  | IndexAccess(e, i) -> IndexAccess(p e, p i)
  | ListLiteral elts -> ListLiteral (List.map p elts)
  | MapLiteral pairs -> MapLiteral (List.map (fun (k, v) -> (p k, p v)) pairs)
  | TupleLiteral elts -> TupleLiteral (List.map p elts)
  | Lambda(params, body) -> Lambda(params, p body)
  | Conditional(c, t, e) -> Conditional(p c, p t, p e)

let rec prefix_calls_in_stmt prefix names stmt =
  let p_e = prefix_calls_in_expr prefix names in
  let p_s = prefix_calls_in_stmt prefix names in
  match stmt with
  | ExprStmt e -> ExprStmt (p_e e)
  | VarDecl(n, t, e) -> VarDecl(n, t, Option.map p_e e)
  | ConstDecl(n, t, e) -> ConstDecl(n, t, p_e e)
  | AssignStmt(l, r) -> AssignStmt(p_e l, p_e r)
  | BlockStmt stmts -> BlockStmt (List.map p_s stmts)
  | IfStmt(c, t, e) -> IfStmt(p_e c, p_s t, Option.map p_s e)
  | WhileStmt(c, b) -> WhileStmt(p_e c, p_s b)
  | ForStmt (ForEach(id, e, b)) -> ForStmt (ForEach(id, p_e e, p_s b))
  | ForStmt (ForRange(id, s, e, b)) -> ForStmt (ForRange(id, p_e s, p_e e, p_s b))
  | FunctionDecl f -> FunctionDecl { f with body = List.map p_s f.body }
  | ReturnStmt e -> ReturnStmt (Option.map p_e e)
  | TryStmt(b, catches, fin) ->
      TryStmt(p_s b, List.map (fun (id, s) -> (id, p_s s)) catches, Option.map p_s fin)
  | ThrowStmt e -> ThrowStmt (p_e e)
  | _ -> stmt

let rec prefix_declarations prefix names decls =
  List.map (fun decl ->
    match decl with
    | DFunction f -> 
        let new_name = if String.contains f.name '.' then f.name else prefix ^ "." ^ f.name in
        DFunction { f with name = new_name; body = List.map (prefix_calls_in_stmt prefix names) f.body }
    | DClass c -> 
        let new_name = if String.contains c.name '.' then c.name else prefix ^ "." ^ c.name in
        DClass { c with name = new_name }
    | DContract c -> 
        let new_name = if String.contains c.name '.' then c.name else prefix ^ "." ^ c.name in
        DContract { c with name = new_name }
    | DModule m -> 
        let new_name = if String.contains m.name '.' then m.name else prefix ^ "." ^ m.name in
        DModule { m with name = new_name; declarations = prefix_declarations prefix names m.declarations }
  ) decls

let rec get_declaration_names decls =
  List.map (fun decl ->
    match decl with
    | DFunction f -> f.name
    | DClass c -> c.name
    | DContract c -> c.name
    | DModule m -> m.name
  ) decls

let rec resolve_imports (p : Ast.program) : Ast.program =
  let stdlib_path = "stdlib/" in
  let resolved_declarations = ref p.declarations in
  let loaded_modules = ref [p.name] in
  
  let rec load_import spec =
    let modname = (match spec with
      | ImportAll m -> m
      | ImportFrom(m, _) -> m
      | ImportAs(m, _) -> m)
    in
    if List.mem modname !loaded_modules then ()
    else (
      loaded_modules := modname :: !loaded_modules;
      let filename = stdlib_path ^ String.lowercase_ascii modname ^ ".vorlang" in
      if Sys.file_exists filename then (
        let imported_program = parse_file filename in
        let resolved_imported = resolve_imports imported_program in
        let actual_modname = resolved_imported.name in
        let names = get_declaration_names resolved_imported.declarations in
        (* Prefix declarations, except for the 'core' module which we want global *)
        let prefixed = if String.lowercase_ascii actual_modname = "core" then
                         resolved_imported.declarations
                       else
                         prefix_declarations actual_modname names resolved_imported.declarations
        in
        resolved_declarations := !resolved_declarations @ prefixed
      ) else ()
    )
  in
  List.iter load_import p.imports;
  { p with declarations = !resolved_declarations }

let parse_file_with_imports filename =
  let p = parse_file filename in
  resolve_imports p
