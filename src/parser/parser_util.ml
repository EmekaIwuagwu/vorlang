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

let rec prefix_calls_in_expr prefix global_names local_names expr =
  let p = prefix_calls_in_expr prefix global_names local_names in
  match expr with
  | Literal _ -> expr
  | Identifier id -> 
      if List.mem id local_names then Identifier id
      else if List.mem id global_names then Identifier (prefix ^ "." ^ id) 
      else expr
  | Self | This | Super as e -> e
  | BinaryOp(op, l, r) -> BinaryOp(op, p l, p r)
  | UnaryOp(op, e) -> UnaryOp(op, p e)
  | Assignment(l, r) -> Assignment(p l, p r)
  | FunctionCall(name, args) ->
      let is_prefixed = String.contains name '.' in
      let new_name = 
        if is_prefixed || List.mem name local_names then name
        else if List.mem name global_names then prefix ^ "." ^ name 
        else name in
      FunctionCall(new_name, List.map p args)
  | MemberAccess(e, m) -> MemberAccess(p e, m)
  | IndexAccess(e, i) -> IndexAccess(p e, p i)
  | ListLiteral elts -> ListLiteral (List.map p elts)
  | MapLiteral pairs -> MapLiteral (List.map (fun (k, v) -> (p k, p v)) pairs)
  | TupleLiteral elts -> TupleLiteral (List.map p elts)
  | Lambda(params, body) -> Lambda(params, prefix_calls_in_expr prefix global_names (params @ local_names) body)
  | Conditional(c, t, e) -> Conditional(p c, p t, p e)
  | New(cls, args) -> 
      let new_cls = if List.mem cls global_names && not (List.mem cls local_names) then prefix ^ "." ^ cls else cls in
      New(new_cls, List.map p args)

let rec prefix_calls_in_stmt prefix global_names local_names stmt =
  let p_e = prefix_calls_in_expr prefix global_names local_names in
  let p_s = prefix_calls_in_stmt prefix global_names local_names in
  match stmt with
  | ExprStmt e -> ExprStmt (p_e e)
  | VarDecl(n, t, e) -> VarDecl(n, t, Option.map p_e e)
  | ConstDecl(n, t, e) -> ConstDecl(n, t, p_e e)
  | AssignStmt(l, r) -> AssignStmt(p_e l, p_e r)
  | BlockStmt stmts -> BlockStmt (List.map p_s stmts)
  | IfStmt(c, t, e) -> IfStmt(p_e c, p_s t, Option.map (prefix_calls_in_stmt prefix global_names local_names) e)
  | WhileStmt(c, b) -> WhileStmt(p_e c, p_s b)
  | ForStmt (ForEach(id, e, b)) -> 
      let inner_local = id :: local_names in
      ForStmt (ForEach(id, p_e e, prefix_calls_in_stmt prefix global_names inner_local b))
  | ForStmt (ForRange(id, s, e, b)) -> 
      let inner_local = id :: local_names in
      ForStmt (ForRange(id, p_e s, p_e e, prefix_calls_in_stmt prefix global_names inner_local b))
  | FunctionDecl f -> 
      let params = List.map (fun (n, _, _) -> n) f.params in
      FunctionDecl { f with body = List.map (prefix_calls_in_stmt prefix global_names (params @ local_names)) f.body }
  | ReturnStmt e -> ReturnStmt (Option.map p_e e)
  | TryStmt(b, catches, fin) ->
      TryStmt(p_s b, 
              List.map (fun (id, s) -> (id, prefix_calls_in_stmt prefix global_names (id :: local_names) s)) catches, 
              Option.map p_s fin)
  | ThrowStmt e -> ThrowStmt (p_e e)
  | _ -> stmt

let rec get_declaration_names decls =
  List.map (fun decl ->
    match decl with
    | DFunction f -> f.name
    | DClass c -> c.name
    | DContract c -> c.name
    | DModule m -> m.name
  ) decls

let rec prefix_declarations prefix names decls =
  List.map (fun decl ->
    match decl with
    | DFunction f -> 
        let new_name = if String.contains f.name '.' then f.name else prefix ^ "." ^ f.name in
        let params = List.map (fun (n, _, _) -> n) f.params in
        DFunction { f with name = new_name; body = List.map (prefix_calls_in_stmt prefix names params) f.body }
    | DClass c -> 
        let new_name = if String.contains c.name '.' then c.name else prefix ^ "." ^ c.name in
        DClass { c with name = new_name }
    | DContract c -> 
        let new_name = if String.contains c.name '.' then c.name else prefix ^ "." ^ c.name in
        DContract { c with name = new_name }
    | DModule m -> 
        let full_name = if m.name = prefix || String.starts_with ~prefix:(prefix ^ ".") m.name 
                        then m.name 
                        else prefix ^ "." ^ m.name in
        let inner_names = get_declaration_names m.declarations in
        DModule { name = full_name; declarations = prefix_declarations full_name inner_names m.declarations }
  ) decls

let resolve_imports (p : Ast.program) : Ast.program =
  let stdlib_path = "stdlib/" in
  
  (* Track globally visited modules (lowercase) to prevent diamond dependency duplication *)
  let visited = ref [String.lowercase_ascii p.name] in
  
  let rec resolve_rec (prog : Ast.program) : Ast.program =
    let resolved_declarations = ref prog.declarations in
    let loaded_modules = ref [] in (* Only for local tracking if needed, but visited is global *)
    
    let core_names = ref [] in
    
    let load_import spec =
      let modname = (match spec with
        | ImportAll m -> m
        | ImportFrom(m, _) -> m
        | ImportAs(m, _) -> m)
      in
      let lower_name = String.lowercase_ascii modname in
      
      (* Check global visited set *)
      if List.mem lower_name !visited then ()
      else (
        visited := lower_name :: !visited;
        Printf.printf "Loading import: %s\n" modname;
        let filename = stdlib_path ^ lower_name ^ ".vorlang" in
        if Sys.file_exists filename then (
          let imported_program = parse_file filename in
          (* Recurse using the same visited ref *)
          let resolved_imported = resolve_rec imported_program in
          let actual_modname = resolved_imported.name in
          
          let names = get_declaration_names resolved_imported.declarations in
          
          let prefixed = if String.lowercase_ascii actual_modname = "core" then (
                           Printf.printf "Flattening core module\n";
                           let core_decls = List.concat (List.map (fun d -> 
                             match d with 
                             | DModule m -> m.declarations 
                             | _ -> [d]
                           ) resolved_imported.declarations) in
                           
                           let core_inner_names = get_declaration_names core_decls in
                           core_names := !core_names @ core_inner_names;
                           
                           core_decls
                         ) else (
                           Printf.printf "Prefixing module %s\n" actual_modname;
                           prefix_declarations actual_modname names resolved_imported.declarations
                         )
          in
          resolved_declarations := !resolved_declarations @ prefixed
        ) else (
          Printf.printf "Warning: Import file %s not found\n" filename
        )
      )
    in
    List.iter load_import prog.imports;
    
    (* Process local declarations *)
    let all_names = get_declaration_names !resolved_declarations in
    
    let is_stdlib_module = String.lowercase_ascii prog.name = "core" || 
                            String.lowercase_ascii prog.name = "io" ||
                            String.lowercase_ascii prog.name = "collections" in
    
    let names_to_prefix = 
      if String.lowercase_ascii prog.name = "core" then []
      else if is_stdlib_module then List.filter (fun n -> not (List.mem n !core_names)) all_names
      else [] 
    in
    
    let local_prefixed = List.map (fun decl ->
      match decl with
      | DModule m -> 
          if String.lowercase_ascii m.name = "core" then decl
          else
          let inner_names = get_declaration_names m.declarations in
          DModule { m with declarations = prefix_declarations m.name inner_names m.declarations }
      | DFunction f ->
          let params = List.map (fun (n, _, _) -> n) f.params in
          DFunction { f with body = List.map (prefix_calls_in_stmt prog.name names_to_prefix params) f.body }
      | _ -> decl
    ) !resolved_declarations in
    
    let body_prefixed = List.map (prefix_calls_in_stmt prog.name names_to_prefix []) prog.body in
    
    { prog with declarations = local_prefixed; body = body_prefixed }
  in
  
  resolve_rec p

let parse_file_with_imports filename =
  let p = parse_file filename in
  resolve_imports p
