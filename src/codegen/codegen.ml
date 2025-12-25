(* Vorlang Code Generation *)
(* OCaml code generation for the Vorlang programming language *)

open Ast
open Tokens

(* Bytecode instructions *)
type instruction =
  | IConstInt of int
  | IConstFloat of float
  | IConstString of string
  | IConstBool of bool
  | IConstNull
  | ILoad of string
  | IStore of string
  | IDefine of string
  | IStoreIndex
  | IStoreMember of string
  | ILoadIndex
  | ILoadMember of string
  | IBinOp of binary_op
  | IUnOp of unary_op
  | ICall of string * int
  | IList of int
  | IMap of int
  | ITuple of int
  | IReturn
  | IJump of string
  | IJumpIfFalse of string
  | IJumpIfTrue of string
  | INew of string * int
  | IPushScope
  | IPopScope
  | ILabel of string
  | IHalt
  | IThrow

(* Bytecode program *)
type bytecode = {
  instructions : instruction array;
  constants : (int, string) Hashtbl.t;
  globals : (string, int) Hashtbl.t;
  functions : (string, int) Hashtbl.t;
}

(* Code generator state *)
type state = {
  mutable instructions : instruction list;
  mutable constants : (int, string) Hashtbl.t;
  mutable globals : (string, int) Hashtbl.t;
  mutable functions : (string, int) Hashtbl.t;
  mutable labels : (string, int) Hashtbl.t;
  mutable next_label : int;
  mutable current_function : string option;
}

(* Create initial state *)
let create_state () =
  {
    instructions = [];
    constants = Hashtbl.create 100;
    globals = Hashtbl.create 100;
    functions = Hashtbl.create 100;
    labels = Hashtbl.create 100;
    next_label = 0;
    current_function = None;
  }

(* Add instruction to current state *)
let add_instruction state instr =
  state.instructions <- instr :: state.instructions

(* Add constant to constant pool *)
let add_constant state value =
  let id = Hashtbl.length state.constants in
  Hashtbl.add state.constants id value;
  id

(* Add global variable *)
let add_global state name =
  let id = Hashtbl.length state.globals in
  Hashtbl.add state.globals name id;
  id

(* Add function *)
let add_function state name =
  let id = Hashtbl.length state.functions in
  Hashtbl.add state.functions name id;
  id

(* Generate unique label *)
let new_label state =
  let label = "L" ^ string_of_int state.next_label in
  state.next_label <- state.next_label + 1;
  label

(* Generate code for expressions *)
let rec generate_expr state = function
  | Literal lit -> generate_literal state lit
  | Identifier id -> add_instruction state (ILoad id)
  | Self -> add_instruction state (ILoad "self")
  | This -> add_instruction state (ILoad "this")
  | Super -> add_instruction state (ILoad "super")
  | BinaryOp(op, left, right) ->
      generate_expr state left;
      generate_expr state right;
      add_instruction state (IBinOp op)
  | UnaryOp(op, expr) ->
      generate_expr state expr;
      add_instruction state (IUnOp op)
  | Assignment(lhs, rhs) ->
      generate_store state lhs rhs;
      (* For now, we don't return the value on the stack *)
      ()
  | FunctionCall(name, args) ->
      List.iter (generate_expr state) args;
      add_instruction state (ICall(name, List.length args))
  | MemberAccess(expr, member) ->
      generate_expr state expr;
      add_instruction state (ILoadMember member)
  | IndexAccess(expr, index) ->
      generate_expr state expr;
      generate_expr state index;
      add_instruction state ILoadIndex
  | ListLiteral exprs ->
      List.iter (generate_expr state) exprs;
      add_instruction state (IList (List.length exprs))
  | MapLiteral pairs ->
      List.iter (fun (k, v) ->
        generate_expr state k;
        generate_expr state v;
      ) pairs;
      add_instruction state (IMap (List.length pairs))
  | TupleLiteral exprs ->
      List.iter (generate_expr state) exprs;
      add_instruction state (ITuple (List.length exprs))
  | Lambda(params, body) ->
      (* Generate anonymous function:
         For now, we'll create a simple function reference
         Full closure support would require capturing environment
      *)
      let lambda_name = "__lambda_" ^ string_of_int state.next_label in
      state.next_label <- state.next_label + 1;
      
      (* Store lambda for later - for now just push a placeholder *)
      (* In a full implementation, we'd generate the function code here *)
      add_instruction state (IConstString lambda_name)
  | Conditional(cond, t, f) ->
      let else_label = new_label state in
      let end_label = new_label state in
      generate_expr state cond;
      add_instruction state (IJumpIfFalse else_label);
      generate_expr state t;
      add_instruction state (IJump end_label);
      add_instruction state (ILabel else_label);
      generate_expr state f;
      add_instruction state (ILabel end_label)
  | New(class_name, args) ->
      List.iter (generate_expr state) args;
      add_instruction state (INew(class_name, List.length args))

and generate_store state lhs rhs =
  match lhs with
  | Identifier name ->
      generate_expr state rhs;
      add_instruction state (IStore name)
  | MemberAccess(container, member) ->
      generate_expr state container;
      generate_expr state rhs;
      add_instruction state (IStoreMember member)
  | IndexAccess(container, index) ->
      generate_expr state container;
      generate_expr state index;
      generate_expr state rhs;
      add_instruction state IStoreIndex
  | _ -> ()

and generate_literal state = function
  | LInteger n -> add_instruction state (IConstInt n)
  | LFloat f -> add_instruction state (IConstFloat f)
  | LString s -> add_instruction state (IConstString s)
  | LBoolean b -> add_instruction state (IConstBool b)
  | LNull -> add_instruction state IConstNull

(* Generate code for statements *)
let rec generate_stmt state = function
  | ExprStmt expr -> generate_expr state expr
  | VarDecl(name, typ, init) ->
      (match init with
       | Some expr -> generate_expr state expr
       | None -> add_instruction state IConstNull);
      add_instruction state (IDefine name)
  | ConstDecl(name, typ, value) ->
      generate_expr state value;
      add_instruction state (IDefine name)
  | AssignStmt(lhs, rhs) ->
      generate_store state lhs rhs
  | BlockStmt stmts ->
      add_instruction state IPushScope;
      List.iter (generate_stmt state) stmts;
      add_instruction state IPopScope
  | IfStmt(cond, then_stmt, else_stmt) ->
      generate_expr state cond;
      let else_label = new_label state in
      let end_label = new_label state in
      add_instruction state (IJumpIfFalse else_label);
      generate_stmt state then_stmt;
      add_instruction state (IJump end_label);
      add_instruction state (ILabel else_label);
      (match else_stmt with
       | Some stmt ->
           generate_stmt state stmt
       | None -> ());
      add_instruction state (ILabel end_label)
  | WhileStmt(cond, body) ->
      let start_label = new_label state in
      let end_label = new_label state in
      add_instruction state (ILabel start_label);
      generate_expr state cond;
      add_instruction state (IJumpIfFalse end_label);
      generate_stmt state body;
      add_instruction state (IJump start_label);
      add_instruction state (ILabel end_label)
  | ForStmt for_loop -> generate_for_loop state for_loop
  | FunctionDecl func -> generate_function state func
  | ReturnStmt expr ->
      (match expr with
       | Some e -> generate_expr state e
       | None -> add_instruction state IConstNull);
      add_instruction state IReturn
  | ClassDecl c -> generate_declaration state (DClass c)
  | ContractDecl c -> generate_declaration state (DContract c)
  | ModuleDecl m -> generate_declaration state (DModule m)
  | BreakStmt -> ()
  | ContinueStmt -> ()
  | TryStmt(body, catches, finally) ->
      (* For now, try-catch is not fully implemented *)
      generate_stmt state body
  | ThrowStmt expr -> 
      generate_expr state expr;
      add_instruction state IThrow
  | ImportStmt _ -> ()
  | ExportStmt _ -> ()

and generate_for_loop state = function
  | ForEach(var, expr, body) ->
      (* Generate code for: 
         var __iter = expr
         var __i = 0
         while __i < List.length(__iter) do
           var = __iter[__i]
           body
           __i = __i + 1
         end while
      *)
      let iter_var = "__iter_" ^ var in
      let index_var = "__i_" ^ var in
      let start_label = new_label state in
      let end_label = new_label state in
      
      (* var __iter = expr *)
      generate_expr state expr;
      add_instruction state (IDefine iter_var);
      
      (* var __i = 0 *)
      add_instruction state (IConstInt 0);
      add_instruction state (IDefine index_var);
      
      (* Loop start *)
      add_instruction state (ILabel start_label);
      
      (* Check: __i < List.length(__iter) *)
      add_instruction state (ILoad index_var);
      add_instruction state (ILoad iter_var);
      add_instruction state (ICall("List.length", 1));
      add_instruction state (IBinOp Lt);
      add_instruction state (IJumpIfFalse end_label);
      
      (* var = __iter[__i] *)
      add_instruction state IPushScope;
      add_instruction state (ILoad iter_var);
      add_instruction state (ILoad index_var);
      add_instruction state ILoadIndex;
      add_instruction state (IDefine var);
      
      (* Execute body *)
      generate_stmt state body;
      
      (* __i = __i + 1 *)
      add_instruction state (ILoad index_var);
      add_instruction state (IConstInt 1);
      add_instruction state (IBinOp Add);
      add_instruction state (IStore index_var);
      
      add_instruction state IPopScope;
      
      (* Jump back to start *)
      add_instruction state (IJump start_label);
      add_instruction state (ILabel end_label)
      
  | ForRange(var, start, end_expr, body) ->
      (* Generate code for:
         var = start
         var __end = end_expr
         while var < __end do
           body
           var = var + 1
         end while
      *)
      let end_var = "__end_" ^ var in
      let start_label = new_label state in
      let loop_end_label = new_label state in
      
      (* var = start *)
      generate_expr state start;
      add_instruction state (IDefine var);
      
      (* var __end = end_expr *)
      generate_expr state end_expr;
      add_instruction state (IDefine end_var);
      
      (* Loop start *)
      add_instruction state (ILabel start_label);
      
      (* Check: var < __end *)
      add_instruction state (ILoad var);
      add_instruction state (ILoad end_var);
      add_instruction state (IBinOp Lt);
      add_instruction state (IJumpIfFalse loop_end_label);
      
      (* Execute body *)
      add_instruction state IPushScope;
      generate_stmt state body;
      add_instruction state IPopScope;
      
      (* var = var + 1 *)
      add_instruction state (ILoad var);
      add_instruction state (IConstInt 1);
      add_instruction state (IBinOp Add);
      add_instruction state (IStore var);
      
      (* Jump back to start *)
      add_instruction state (IJump start_label);
      add_instruction state (ILabel loop_end_label)


and generate_function state func =
  let old_function = state.current_function in
  state.current_function <- Some func.name;
  ignore (add_function state func.name);
  add_instruction state (ILabel func.name);
  add_instruction state IPushScope;
  List.iter (fun (name, _, _) ->
    add_instruction state (IDefine name)
  ) (List.rev func.params);
  List.iter (generate_stmt state) func.body;
  add_instruction state IReturn;
  add_instruction state IPopScope;
  state.current_function <- old_function

and generate_declaration state = function
  | DFunction func -> generate_function state func
  | DClass class_def ->
      List.iter (generate_function state) class_def.methods
  | DContract contract_def ->
      List.iter (generate_function state) contract_def.methods
  | DModule module_def ->
      List.iter (generate_declaration state) module_def.declarations

(* Generate code for the entire program *)
let rec generate_program (program : Ast.program) =
  let state = create_state () in

  (* Generate built-in functions *)
  ignore (generate_builtin_functions state);

  (* Generate declarations *)
  List.iter (generate_declaration state) program.declarations;

  (* Generate main entry point *)
  add_instruction state (ILabel "main");
  add_instruction state IPushScope;
  (* Call the main function if it exists *)
  if Hashtbl.mem state.functions "main" then
    add_instruction state (ICall("main", 0))
  else
    ();
  
  (* Generate body statements *)
  List.iter (generate_stmt state) program.body;

  add_instruction state IHalt;
  add_instruction state IPopScope;

  (* Create bytecode *)
  {
    instructions = Array.of_list (List.rev state.instructions);
    constants = state.constants;
    globals = state.globals;
    functions = state.functions;
  }

(* Generate built-in functions *)
and generate_builtin_functions state =
  (* Built-in print function *)
  ignore (add_function state "print");
  add_instruction state (ILabel "print");
  add_instruction state IPushScope;
  (* For now, just handle the parameter *)
  add_instruction state (ILoad "message");
  (* In a full implementation, we'd call the actual print function *)
  add_instruction state IConstNull;
  add_instruction state IReturn;
  add_instruction state IPopScope;

  (* Built-in str function for type conversion *)
  ignore (add_function state "str");
  add_instruction state (ILabel "str");
  add_instruction state IPushScope;
  add_instruction state (ILoad "value");
  add_instruction state (IConstString "");
  add_instruction state IReturn;
  add_instruction state IPopScope;

  ()

(* Print bytecode for debugging *)
let rec print_bytecode (bytecode : bytecode) =
  Printf.printf "Bytecode:\n";
  Array.iteri (fun i instr ->
    Printf.printf "%d: %s\n" i (string_of_instruction instr)
  ) bytecode.instructions;
  Printf.printf "\nConstants:\n";
  Hashtbl.iter (fun id value ->
    Printf.printf "%d: %s\n" id value
  ) bytecode.constants;
  Printf.printf "\nGlobals:\n";
  Hashtbl.iter (fun name id ->
    Printf.printf "%s: %d\n" name id
  ) bytecode.globals;
  Printf.printf "\nFunctions:\n";
  Hashtbl.iter (fun name id ->
    Printf.printf "%s: %d\n" name id
  ) bytecode.functions

and string_of_instruction = function
  | IConstInt n -> "IConstInt " ^ string_of_int n
  | IConstFloat f -> "IConstFloat " ^ string_of_float f
  | IConstString s -> "IConstString " ^ s
  | IConstBool b -> "IConstBool " ^ string_of_bool b
  | IConstNull -> "IConstNull"
  | ILoad name -> "ILoad " ^ name
  | IStore name -> "IStore " ^ name
  | IDefine name -> "IDefine " ^ name
  | IStoreIndex -> "IStoreIndex"
  | IStoreMember name -> "IStoreMember " ^ name
  | ILoadIndex -> "ILoadIndex"
  | ILoadMember name -> "ILoadMember " ^ name
  | IBinOp op -> "IBinOp " ^ string_of_binary_op op
  | IUnOp op -> "IUnOp " ^ string_of_unary_op op
  | ICall(name, argc) -> "ICall " ^ name ^ " " ^ string_of_int argc
  | IList n -> "IList " ^ string_of_int n
  | IMap n -> "IMap " ^ string_of_int n
  | ITuple n -> "ITuple " ^ string_of_int n
  | IReturn -> "IReturn"
  | IJump label -> "IJump " ^ label
  | IJumpIfFalse label -> "IJumpIfFalse " ^ label
  | IJumpIfTrue label -> "IJumpIfTrue " ^ label
  | IPushScope -> "IPushScope"
  | IPopScope -> "IPopScope"
  | ILabel name -> "ILabel " ^ name
  | IHalt -> "IHalt"
  | IThrow -> "IThrow"
  | INew(class_name, argc) -> "INew " ^ class_name ^ " " ^ string_of_int argc

and string_of_binary_op = function
  | Add -> "Add"
  | Sub -> "Sub"
  | Mul -> "Mul"
  | Div -> "Div"
  | Mod -> "Mod"
  | Pow -> "Pow"
  | Eq -> "Eq"
  | Ne -> "Ne"
  | Lt -> "Lt"
  | Gt -> "Gt"
  | Le -> "Le"
  | Ge -> "Ge"
  | And -> "And"
  | Or -> "Or"

and string_of_unary_op = function
  | Neg -> "Neg"
  | Not -> "Not"
