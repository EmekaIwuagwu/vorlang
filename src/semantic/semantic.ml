(* Vorlang Semantic Analysis *)
(* OCaml semantic analysis for the Vorlang programming language *)

open Ast
open Tokens

exception Semantic_error of string

type symbol_kind =
  | VarSymbol
  | ConstSymbol
  | FunctionSymbol
  | ClassSymbol
  | ContractSymbol
  | ModuleSymbol
  | ParameterSymbol

type symbol = {
  name : string;
  kind : symbol_kind;
  typ : type_expr;
  mutable value : expr option;
  mutable scope : scope option;
}

and scope = {
  symbols : (string, symbol) Hashtbl.t;
  parent : scope option;
}

type environment = {
  global_scope : scope;
  mutable current_scope : scope;
}

(* Create a new scope *)
let create_scope parent =
  { symbols = Hashtbl.create 100; parent }

(* Create a new environment *)
let create_environment () =
  let global_scope = create_scope None in
  { global_scope; current_scope = global_scope }

(* Enter a new scope *)
let enter_scope env =
  env.current_scope <- create_scope (Some env.current_scope)

(* Exit current scope *)
let exit_scope env =
  match env.current_scope.parent with
  | Some parent -> env.current_scope <- parent
  | None -> raise (Semantic_error "Cannot exit global scope")

(* Add a symbol to current scope *)
let add_symbol env name kind typ value =
  if Hashtbl.mem env.current_scope.symbols name then
    raise (Semantic_error ("Symbol '" ^ name ^ "' already declared"));
  Hashtbl.add env.current_scope.symbols name { name; kind; typ; value; scope = None }

let add_builtin env name kind typ value =
  Hashtbl.replace env.current_scope.symbols name { name; kind; typ; value; scope = None }

(* Lookup a symbol in current scope and parent scopes *)
let lookup_symbol env name =
  let rec find scope =
    match scope with
    | None -> None
    | Some s ->
        if Hashtbl.mem s.symbols name then
          Some (Hashtbl.find s.symbols name)
        else
          find s.parent
  in
  find (Some env.current_scope)
  
let rec resolve_dotted scope parts prefix =
  match parts with
  | [] -> None
  | [last] -> 
      let full_name = if prefix = "" then last else prefix ^ "." ^ last in
      Hashtbl.find_opt scope.symbols full_name
  | head :: rest ->
      let full_name = if prefix = "" then head else prefix ^ "." ^ head in
      match Hashtbl.find_opt scope.symbols full_name with
      | Some s -> 
          (match s.scope with
           | Some sc -> resolve_dotted sc rest full_name
           | None -> None)
      | None -> None

let lookup_symbol_dotted env name =
  let parts = String.split_on_char '.' name in
  match parts with
  | [] -> None
  | [single] -> lookup_symbol env single
  | head :: rest ->
      (match lookup_symbol env head with
       | Some s -> 
           (match s.scope with
            | Some sc -> resolve_dotted sc rest head
            | None -> None)
       | None -> None)

(* Check if a type is valid *)
let rec is_valid_type = function
  | TInteger | TFloat | TString | TBoolean | TNull | TIdentifier _ -> true
  | TList t -> is_valid_type t
  | TMap(k, v) -> is_valid_type k && is_valid_type v
  | TSet t -> is_valid_type t
  | TTuple ts -> List.for_all is_valid_type ts
  | TFunction(args, ret) -> List.for_all is_valid_type args && is_valid_type ret
  | TOptional t -> is_valid_type t

let rec string_of_type = function
  | TInteger -> "Integer"
  | TFloat -> "Float"
  | TString -> "String"
  | TBoolean -> "Boolean"
  | TNull -> "Null"
  | TIdentifier id -> id
  | TList t -> "List<" ^ string_of_type t ^ ">"
  | TMap(k, v) -> "Map<" ^ string_of_type k ^ ", " ^ string_of_type v ^ ">"
  | TSet t -> "Set<" ^ string_of_type t ^ ">"
  | TTuple ts -> "(" ^ String.concat ", " (List.map string_of_type ts) ^ ")"
  | TFunction(args, ret) -> "(" ^ String.concat ", " (List.map string_of_type args) ^ ") -> " ^ string_of_type ret
  | TOptional t -> "Optional<" ^ string_of_type t ^ ">"

let normalize_type = function
  | TIdentifier "Integer" | TIdentifier "Int" -> TInteger
  | TIdentifier "Float" -> TFloat
  | TIdentifier "String" -> TString
  | TIdentifier "Boolean" | TIdentifier "Bool" -> TBoolean
  | TIdentifier "Array" | TIdentifier "List" -> TList (TIdentifier "Any")
  | TIdentifier "Map" -> TMap (TIdentifier "Any", TIdentifier "Any")
  | TIdentifier "Null" -> TNull
  | t -> t

(* Type compatibility check *)
let rec types_compatible expected actual =
  let expected = normalize_type expected in
  let actual = normalize_type actual in
  match expected, actual with
  | TIdentifier "Any", _ -> true
  | _, TIdentifier "Any" -> true
  | TInteger, TInteger -> true
  | TFloat, TFloat -> true
  | TString, TString -> true
  | TBoolean, TBoolean -> true
  | TNull, TNull -> true
  | TIdentifier id1, TIdentifier id2 -> id1 = id2
  | TList t1, TList t2 -> types_compatible t1 t2
  | TMap(k1, v1), TMap(k2, v2) -> types_compatible k1 k2 && types_compatible v1 v2
  | TSet t1, TSet t2 -> types_compatible t1 t2
  | TTuple ts1, TTuple ts2 ->
      List.length ts1 = List.length ts2 &&
      List.for_all2 (fun t1 t2 -> types_compatible t1 t2) ts1 ts2
  | TFunction(args1, ret1), TFunction(args2, ret2) ->
      List.length args1 = List.length args2 &&
      List.for_all2 types_compatible args1 args2 &&
      types_compatible ret1 ret2
  | TOptional t1, t2 -> types_compatible t1 t2
  | t1, TOptional t2 -> types_compatible t1 t2
  | _ -> false

(* Semantic analysis of expressions *)
let rec analyze_expr env = function
  | Literal lit -> analyze_literal lit
  | Identifier id ->
      (match lookup_symbol env id with
       | Some symbol -> symbol.typ
       | None -> raise (Semantic_error ("Undefined identifier: " ^ id)))
  | BinaryOp(op, left, right) ->
      let left_type = analyze_expr env left in
      let right_type = analyze_expr env right in
      analyze_binary_op op left_type right_type
  | UnaryOp(op, expr) ->
      let expr_type = analyze_expr env expr in
      analyze_unary_op op expr_type
  | Assignment(lhs, rhs) ->
      let rhs_type = analyze_expr env rhs in
      (match lhs with
       | Identifier id ->
           (match lookup_symbol env id with
            | Some symbol ->
                if symbol.kind = ConstSymbol then
                  raise (Semantic_error ("Cannot assign to constant: " ^ id));
                if not (types_compatible symbol.typ rhs_type) then
                  raise (Semantic_error ("Type mismatch in assignment to " ^ id));
                symbol.typ
            | None -> raise (Semantic_error ("Undefined identifier: " ^ id)))
       | MemberAccess(obj, _) ->
           ignore (analyze_expr env obj);
           rhs_type
       | IndexAccess(arr, idx) ->
           ignore (analyze_expr env arr);
           ignore (analyze_expr env idx);
           rhs_type
       | _ -> raise (Semantic_error "Invalid assignment target"))
  | FunctionCall(name, args) ->
      let symbol_opt = lookup_symbol_dotted env name in
      (match symbol_opt with
       | Some symbol ->
           (match normalize_type symbol.typ with
            | TFunction(param_types, return_type) ->
                if List.length args != List.length param_types then
                   raise (Semantic_error ("Argument count mismatch in function call: " ^ name));
                List.iter2 (fun arg param_type ->
                  let arg_type = analyze_expr env arg in
                  if not (types_compatible param_type arg_type) then
                    raise (Semantic_error ("Argument type mismatch in function call: " ^ name))
                ) args param_types;
                return_type
            | TIdentifier "Function" ->
                (* Generic function type - accept any args, return Any *)
                List.iter (fun arg -> ignore (analyze_expr env arg)) args;
                TIdentifier "Any"
            | _ -> raise (Semantic_error ("Cannot call non-function: " ^ name)))
       | None -> 
           (* Fallback for system primitives that might not be in symtab yet or are magic *)
           if List.mem name ["print"; "str"; "typeOf"; "panic"; "toString"; "toInt"; "toFloat"; "toBool"] ||
              String.starts_with ~prefix:"Sys." name ||
              String.starts_with ~prefix:"List." name ||
              String.starts_with ~prefix:"Map." name ||
              String.starts_with ~prefix:"String." name ||
              String.starts_with ~prefix:"Maths." name then
             (List.iter (fun arg -> ignore (analyze_expr env arg)) args; TIdentifier "Any")
           else
             raise (Semantic_error ("Undefined function: " ^ name)))
  | MemberAccess(expr, member) ->
      let obj_type = analyze_expr env expr in
      (match obj_type with
       | TIdentifier id ->
           (match lookup_symbol_dotted env id with
            | Some symbol ->
                (match symbol.scope with
                 | Some sc ->
                     let full_member_name = id ^ "." ^ member in
                     (match Hashtbl.find_opt sc.symbols full_member_name with
                      | Some s -> s.typ
                      | None -> TIdentifier "Any")
                 | None -> TIdentifier "Any")
            | None -> TIdentifier "Any")
       | _ -> TIdentifier "Any")
  | IndexAccess(expr, index) ->
      ignore (analyze_expr env expr);
      ignore (analyze_expr env index);
      (* For now, we'll assume index access is valid *)
      (* In a full implementation, we'd check if the type supports indexing *)
      TIdentifier "Any"
  | ListLiteral exprs ->
      if List.length exprs = 0 then TList (TIdentifier "Any")
      else
        let elem_type = analyze_expr env (List.hd exprs) in
        List.iter (fun expr ->
          let expr_type = analyze_expr env expr in
          if not (types_compatible elem_type expr_type) then
            raise (Semantic_error "Inconsistent types in list literal")
        ) exprs;
        TList elem_type
  | MapLiteral pairs ->
      if List.length pairs = 0 then TMap(TIdentifier "Any", TIdentifier "Any")
      else
        let (k_expr, v_expr) = List.hd pairs in
        let k_type = analyze_expr env k_expr in
        let v_type_ref = ref (analyze_expr env v_expr) in
        let k_type_ref = ref k_type in
        List.iter (fun (k, v) ->
          let k_type' = analyze_expr env k in
          let v_type' = analyze_expr env v in
          (* If key types don't match, use Any *)
          if not (types_compatible !k_type_ref k_type') then
            k_type_ref := TIdentifier "Any";
          (* If value types don't match, use Any *)
          if not (types_compatible !v_type_ref v_type') then
            v_type_ref := TIdentifier "Any"
        ) pairs;
        TMap(!k_type_ref, !v_type_ref)
  | TupleLiteral exprs ->
      let types = List.map (analyze_expr env) exprs in
      TTuple types
  | Lambda(params, body) ->
      enter_scope env;
      List.iter (fun name ->
        add_symbol env name ParameterSymbol (TIdentifier "Any") None
      ) params;
      let return_type = analyze_expr env body in
      exit_scope env;
      TFunction(List.map (fun _ -> TIdentifier "Any") params, return_type)
  | Conditional(cond, t, f) ->
      let cond_type = analyze_expr env cond in
      if not (types_compatible cond_type TBoolean) then
        raise (Semantic_error "Conditional condition must be boolean");
      let t_type = analyze_expr env t in
      let f_type = analyze_expr env f in
      if not (types_compatible t_type f_type) then
        raise (Semantic_error "Conditional branches must have compatible types");
      t_type
  | New(class_name, args) ->
      (match lookup_symbol env class_name with
       | Some symbol when symbol.kind = ClassSymbol ->
           List.iter (fun arg -> ignore (analyze_expr env arg)) args;
           TIdentifier class_name
       | _ -> raise (Semantic_error ("Undefined class: " ^ class_name)))

and analyze_literal = function
  | LInteger _ -> TInteger
  | LFloat _ -> TFloat
  | LString _ -> TString
  | LBoolean _ -> TBoolean
  | LNull -> TNull

and analyze_binary_op op left_type right_type =
  match op with
  | Add ->
      let left_normalized = normalize_type left_type in
      let right_normalized = normalize_type right_type in
      (* Allow Any to participate in addition *)
      if left_normalized = TIdentifier "Any" || right_normalized = TIdentifier "Any" then
        TIdentifier "Any"
      else if types_compatible left_type TString && types_compatible right_type TString then
        TString
      else if (types_compatible left_type TInteger && types_compatible right_type TInteger) ||
              (types_compatible left_type TFloat && types_compatible right_type TFloat) ||
              (types_compatible left_type TInteger && types_compatible right_type TFloat) ||
              (types_compatible left_type TFloat && types_compatible right_type TInteger) then
        if types_compatible left_type TFloat || types_compatible right_type TFloat then TFloat else TInteger
      else
        raise (Semantic_error ("Addition requires numeric types or string types, but got " ^ 
                              string_of_type left_type ^ " and " ^ string_of_type right_type))
  | Sub | Mul | Div | Mod ->
      let left_normalized = normalize_type left_type in
      let right_normalized = normalize_type right_type in
      (* Allow Any to participate in arithmetic *)
      if left_normalized = TIdentifier "Any" || right_normalized = TIdentifier "Any" then
        TIdentifier "Any"
      else if not ((types_compatible left_type TInteger || types_compatible left_type TFloat) &&
                   (types_compatible right_type TInteger || types_compatible right_type TFloat)) then
        raise (Semantic_error ("Arithmetic operations require numeric types, but got " ^ 
                              string_of_type left_type ^ " and " ^ string_of_type right_type))
      else if types_compatible left_type TFloat || types_compatible right_type TFloat then 
        TFloat 
      else 
        TInteger
  | Pow ->
      let left_normalized = normalize_type left_type in
      let right_normalized = normalize_type right_type in
      (* Allow Any to participate in power operations *)
      if left_normalized = TIdentifier "Any" || right_normalized = TIdentifier "Any" then
        TIdentifier "Any"
      else if not ((types_compatible left_type TInteger || types_compatible left_type TFloat) &&
                   (types_compatible right_type TInteger || types_compatible right_type TFloat)) then
        raise (Semantic_error "Power operation requires numeric types")
      else if types_compatible left_type TFloat || types_compatible right_type TFloat then 
        TFloat 
      else 
        TInteger
  | Eq | Ne | Lt | Gt | Le | Ge ->
      let left_normalized = normalize_type left_type in
      let right_normalized = normalize_type right_type in
      let is_numeric t = types_compatible t TInteger || types_compatible t TFloat in
      if is_numeric left_normalized && is_numeric right_normalized then
        TBoolean
      else if types_compatible left_type right_type then
        TBoolean
      else
        raise (Semantic_error "Comparison operations require compatible types")
  | And | Or ->
      if not (types_compatible left_type TBoolean && types_compatible right_type TBoolean) then
        raise (Semantic_error "Logical operations require boolean types");
      TBoolean

and analyze_unary_op op expr_type =
  match op with
  | Neg ->
      if not (types_compatible expr_type TInteger || types_compatible expr_type TFloat) then
        raise (Semantic_error "Negation requires numeric type");
      expr_type
  | Not ->
      if not (types_compatible expr_type TBoolean) then
        raise (Semantic_error "Logical NOT requires boolean type");
      TBoolean

(* Semantic analysis of statements *)
let rec analyze_stmt env = function
  | ExprStmt expr -> ignore (analyze_expr env expr)
  | VarDecl(name, typ, init) ->
      let typ = match typ with
        | Some t -> if is_valid_type t then t else raise (Semantic_error "Invalid type");
        | None -> TIdentifier "Any"
      in
      let init_type = match init with
        | Some expr -> analyze_expr env expr
        | None -> TIdentifier "Any"
      in
      if init <> None && not (types_compatible typ init_type) then
        raise (Semantic_error ("Type mismatch in variable declaration: " ^ name));
      add_symbol env name VarSymbol typ init
  | ConstDecl(name, typ, value) ->
      let typ = match typ with
        | Some t -> if is_valid_type t then t else raise (Semantic_error "Invalid type");
        | None -> TIdentifier "Any"
      in
      let value_type = analyze_expr env value in
      if not (types_compatible typ value_type) then
        raise (Semantic_error ("Type mismatch in constant declaration: " ^ name));
      add_symbol env name ConstSymbol typ (Some value)
  | AssignStmt(lhs, rhs) ->
      ignore (analyze_expr env (Assignment(lhs, rhs)))
  | BlockStmt stmts ->
      enter_scope env;
      List.iter (analyze_stmt env) stmts;
      exit_scope env
  | IfStmt(cond, then_stmt, else_stmt) ->
      let cond_type = analyze_expr env cond in
      if not (types_compatible cond_type TBoolean) then
        raise (Semantic_error "If condition must be boolean");
      analyze_stmt env then_stmt;
      (match else_stmt with
       | Some stmt -> analyze_stmt env stmt
       | None -> ())
  | WhileStmt(cond, body) ->
      let cond_type = analyze_expr env cond in
      if not (types_compatible cond_type TBoolean) then
        raise (Semantic_error "While condition must be boolean");
      analyze_stmt env body
  | ForStmt for_loop -> analyze_for_loop env for_loop
  | FunctionDecl func -> analyze_function env func
  | ReturnStmt expr ->
      (match expr with
       | Some e -> ignore (analyze_expr env e)
       | None -> ())
  | ClassDecl c -> analyze_declaration_body env (DClass c)
  | ContractDecl c -> analyze_declaration_body env (DContract c)
  | ModuleDecl m -> analyze_declaration_body env (DModule m)
  | BreakStmt | ContinueStmt -> ()
  | TryStmt(body, catches, finally) ->
      analyze_stmt env body;
      List.iter (fun (_, stmt) -> analyze_stmt env stmt) catches;
      (match finally with
       | Some stmt -> analyze_stmt env stmt
       | None -> ())
  | ThrowStmt expr -> ignore (analyze_expr env expr)
  | ImportStmt _ -> ()
  | ExportStmt _ -> ()

and analyze_for_loop env = function
  | ForEach(var, expr, body) ->
      ignore (analyze_expr env expr);
      enter_scope env;
      add_symbol env var VarSymbol (TIdentifier "Any") None;
      analyze_stmt env body;
      exit_scope env
  | ForRange(var, start, end_expr, body) ->
      ignore (analyze_expr env start);
      ignore (analyze_expr env end_expr);
      enter_scope env;
      add_symbol env var VarSymbol TInteger None;
      analyze_stmt env body;
      exit_scope env

and analyze_function env func =
  enter_scope env;
  List.iter (fun (name, typ, _) ->
    add_symbol env name ParameterSymbol typ None
  ) func.params;
  List.iter (analyze_stmt env) func.body;
  exit_scope env

and analyze_declaration_body env = function
  | DFunction func -> analyze_function env func
  | DClass class_def ->
      let parent_scope = env.current_scope in
      enter_scope env;
      let class_scope = env.current_scope in
      (match Hashtbl.find_opt parent_scope.symbols class_def.name with
       | Some s -> s.scope <- Some class_scope
       | None -> ());
      List.iter (fun (name, typ, init) ->
        add_symbol env name VarSymbol typ None;
        match init with
        | Some expr -> ignore (analyze_expr env expr)
        | None -> ()
      ) class_def.fields;
      List.iter (fun (func : function_def) ->
        let param_types = List.map (fun (_, t, _) -> t) func.params in
        let ret_type = match func.return_type with Some t -> t | None -> TNull in
        add_symbol env func.name FunctionSymbol (TFunction(param_types, ret_type)) None
      ) class_def.methods;
      List.iter (analyze_function env) class_def.methods;
      exit_scope env
  | DContract contract_def ->
      let parent_scope = env.current_scope in
      enter_scope env;
      let contract_scope = env.current_scope in
      (match Hashtbl.find_opt parent_scope.symbols contract_def.name with
       | Some s -> s.scope <- Some contract_scope
       | None -> ());
      List.iter (fun (name, typ, init) ->
        add_symbol env name VarSymbol typ None;
        match init with
        | Some expr -> ignore (analyze_expr env expr)
        | None -> ()
      ) contract_def.fields;
      List.iter (fun (func : function_def) ->
        let param_types = List.map (fun (_, t, _) -> t) func.params in
        let ret_type = match func.return_type with Some t -> t | None -> TNull in
        add_symbol env func.name FunctionSymbol (TFunction(param_types, ret_type)) None
      ) contract_def.methods;
      List.iter (analyze_function env) contract_def.methods;
      exit_scope env
  | DModule module_def ->
      let parent_scope = env.current_scope in
      enter_scope env;
      let module_scope = env.current_scope in
      (match Hashtbl.find_opt parent_scope.symbols module_def.name with
       | Some s -> s.scope <- Some module_scope
       | None -> ());
      (* Pass 1: Add members *)
      List.iter (fun decl ->
        match decl with
        | DFunction func ->
            let param_types = List.map (fun (_, t, _) -> t) func.params in
            let ret_type = match func.return_type with Some t -> t | None -> TNull in
            add_symbol env func.name FunctionSymbol (TFunction(param_types, ret_type)) None
        | DClass c -> add_symbol env c.name ClassSymbol (TIdentifier c.name) None
        | DContract c -> add_symbol env c.name ContractSymbol (TIdentifier c.name) None
        | DModule m -> add_symbol env m.name ModuleSymbol (TIdentifier m.name) None
      ) module_def.declarations;
      (* Pass 2: Analyze bodies *)
      List.iter (analyze_declaration_body env) module_def.declarations;
      exit_scope env

(* Semantic analysis of the entire program *)
let rec analyze_program program =
  let env = create_environment () in
  
  (* Add built-in functions and types to global scope *)
  (* Add built-in primitives to global scope *)
  add_builtin env "print" FunctionSymbol (TFunction([TIdentifier "Any"], TNull)) None;
  add_builtin env "str" FunctionSymbol (TFunction([TIdentifier "Any"], TString)) None;
  add_builtin env "typeOf" FunctionSymbol (TFunction([TIdentifier "Any"], TString)) None;
  add_builtin env "panic" FunctionSymbol (TFunction([TIdentifier "Any"], TNull)) None;
  add_builtin env "toString" FunctionSymbol (TFunction([TIdentifier "Any"], TString)) None;
  add_builtin env "toInt" FunctionSymbol (TFunction([TIdentifier "Any"], TInteger)) None;
  add_builtin env "toFloat" FunctionSymbol (TFunction([TIdentifier "Any"], TFloat)) None;
  add_builtin env "toBool" FunctionSymbol (TFunction([TIdentifier "Any"], TBoolean)) None;
  add_builtin env "Sys.typeOf" FunctionSymbol (TFunction([TIdentifier "Any"], TString)) None;
  add_builtin env "Sys.panic" FunctionSymbol (TFunction([TIdentifier "Any"], TNull)) None;
  add_builtin env "Sys.toString" FunctionSymbol (TFunction([TIdentifier "Any"], TString)) None;
  add_builtin env "Sys.toInt" FunctionSymbol (TFunction([TIdentifier "Any"], TInteger)) None;
  add_builtin env "Sys.toFloat" FunctionSymbol (TFunction([TIdentifier "Any"], TFloat)) None;
  add_builtin env "Sys.toBool" FunctionSymbol (TFunction([TIdentifier "Any"], TBoolean)) None;
  add_builtin env "List.length" FunctionSymbol (TFunction([TIdentifier "Any"], TInteger)) None;
  add_builtin env "List.append" FunctionSymbol (TFunction([TIdentifier "Any"; TIdentifier "Any"], TNull)) None;
  add_builtin env "Map.size" FunctionSymbol (TFunction([TIdentifier "Any"], TInteger)) None;
  add_builtin env "Map.keys" FunctionSymbol (TFunction([TIdentifier "Any"], TList(TString))) None;
  add_builtin env "Maths.floor" FunctionSymbol (TFunction([TFloat], TInteger)) None;
  add_builtin env "Maths.ceil" FunctionSymbol (TFunction([TFloat], TInteger)) None;
  add_builtin env "Maths.sqrt" FunctionSymbol (TFunction([TFloat], TFloat)) None;
  add_builtin env "Maths.sin" FunctionSymbol (TFunction([TFloat], TFloat)) None;
  add_builtin env "Maths.cos" FunctionSymbol (TFunction([TFloat], TFloat)) None;
  add_builtin env "Maths.random" FunctionSymbol (TFunction([], TFloat)) None;
  add_builtin env "String.length" FunctionSymbol (TFunction([TString], TInteger)) None;
  add_builtin env "String.slice" FunctionSymbol (TFunction([TString; TInteger; TInteger], TString)) None;
  add_builtin env "String.split" FunctionSymbol (TFunction([TString; TString], TList(TString))) None;
  add_builtin env "String.indexOf" FunctionSymbol (TFunction([TString; TString], TInteger)) None;
  add_builtin env "String.lastIndexOf" FunctionSymbol (TFunction([TString; TString], TInteger)) None;
  add_builtin env "String.upper" FunctionSymbol (TFunction([TString], TString)) None;
  add_builtin env "String.lower" FunctionSymbol (TFunction([TString], TString)) None;
  
  (* Analyze imports *)
  List.iter (fun _ -> ()) program.imports;
  
  (* First pass: Add all top-level declarations (functions, classes) to global scope *)
  List.iter (fun decl ->
    match decl with
    | DFunction func ->
        let param_types = List.map (fun (_, t, _) -> t) func.params in
        let ret_type = match func.return_type with Some t -> t | None -> TNull in
        let name = func.name in
        let is_primitive = List.mem name [
          "print"; "str"; "typeOf"; "panic"; "toString"; "toInt"; "toFloat"; "toBool";
          "Sys.typeOf"; "Sys.panic"; "Sys.toString"; "Sys.toInt"; "Sys.toFloat"; "Sys.toBool";
          "List.length"; "List.append"; "Map.size"; "Map.keys";
          "Maths.floor"; "Maths.ceil"; "Maths.sqrt"; "Maths.sin"; "Maths.cos"; "Maths.random";
          "String.length"; "String.slice"; "String.split"; "String.indexOf"; "String.lastIndexOf"; "String.upper"; "String.lower"
        ] in
        if is_primitive then
          add_builtin env name FunctionSymbol (TFunction(param_types, ret_type)) None
        else
          add_symbol env name FunctionSymbol (TFunction(param_types, ret_type)) None
    | DClass c -> add_symbol env c.name ClassSymbol (TIdentifier c.name) None
    | DContract c -> add_symbol env c.name ContractSymbol (TIdentifier c.name) None
    | DModule m -> add_symbol env m.name ModuleSymbol (TIdentifier m.name) None
  ) program.declarations;
  
  (* Second pass: Analyze declaration bodies *)
  List.iter (analyze_declaration_body env) program.declarations;
  
  (* Analyze body statements *)
  List.iter (analyze_stmt env) program.body

(* Helper function to convert type to string *)
and string_of_type_expr = function
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
