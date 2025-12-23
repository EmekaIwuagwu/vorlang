(* Vorlang Virtual Machine *)
open Ast
open Codegen

type value =
  | VInt of int
  | VFloat of float
  | VString of string
  | VBool of bool
  | VNull
  | VMap of (string, value) Hashtbl.t
  | VList of value array ref

exception Runtime_error of string

type frame = {
  return_ip : int;
  saved_scopes : (string, value) Hashtbl.t list;
}

type state = {
  mutable instructions : instruction array;
  mutable ip : int;
  mutable stack : value list;
  mutable scopes : (string, value) Hashtbl.t list;
  mutable call_stack : frame list;
  labels : (string, int) Hashtbl.t;
  mutable halted : bool;
}

let create_state (bytecode : Codegen.bytecode) : state =
  let labels = Hashtbl.create 20 in
  Array.iteri (fun i instr ->
    match instr with
    | ILabel name -> Hashtbl.add labels name i
    | _ -> ()
  ) bytecode.instructions;
  let initial_ip = match Hashtbl.find_opt labels "main" with
    | Some idx -> idx
    | None -> 0
  in
  {
    instructions = bytecode.instructions;
    ip = initial_ip;
    stack = [];
    scopes = [Hashtbl.create 50]; (* Global scope *)
    call_stack = [];
    labels = labels;
    halted = false;
  }

let push state v = state.stack <- v :: state.stack

let pop state =
  match state.stack with
  | [] -> raise (Runtime_error "Stack underflow")
  | v :: rest ->
      state.stack <- rest;
      v

let peek state =
  match state.stack with
  | [] -> raise (Runtime_error "Stack underflow")
  | v :: _ -> v

let lookup state name =
  let rec find = function
    | [] -> None
    | scope :: rest ->
        if Hashtbl.mem scope name then Some (Hashtbl.find scope name)
        else find rest
  in
  find state.scopes

let store state name v =
  let rec update = function
    | [] -> Hashtbl.add (List.hd state.scopes) name v
    | scope :: rest ->
        if Hashtbl.mem scope name then Hashtbl.replace scope name v
        else update rest
  in
  update state.scopes

let rec string_of_value = function
  | VInt n -> string_of_int n
  | VFloat f -> string_of_float f
  | VString s -> s
  | VBool b -> string_of_bool b
  | VNull -> "null"
  | VMap m -> 
      let pairs = Hashtbl.fold (fun k v acc -> (k ^ ": " ^ string_of_value v) :: acc) m [] in
      "{" ^ String.concat ", " pairs ^ "}"
  | VList arr -> 
      let elts = Array.to_list !arr in
      "[" ^ String.concat ", " (List.map string_of_value elts) ^ "]"

let handle_builtin state name argc =
  match name, argc with
  | "print", 1 ->
      let v = pop state in
      print_endline (string_of_value v);
      push state VNull
  | "str", 1 ->
      let v = pop state in
      push state (VString (string_of_value v))
  | "Net.get", 1 ->
      let v_url = pop state in
      let url = string_of_value v_url in
      let cmd = Printf.sprintf "curl -s \"%s\"" url in
      let ic = Unix.open_process_in cmd in
      let b = Buffer.create 1024 in
      (try
         while true do
           Buffer.add_channel b ic 1
         done
       with End_of_file -> ());
      let _status = Unix.close_process_in ic in
      let body = Buffer.contents b in
      let m = Hashtbl.create 1 in
      Hashtbl.add m "body" (VString (String.trim body));
      push state (VMap m)
  | "List.length", 1 ->
      let v = pop state in
      (match v with
       | VList arr -> push state (VInt (Array.length !arr))
       | _ -> raise (Runtime_error "List.length expects a list"))
  | "List.append", 2 ->
      let item = pop state in
      let v_list = pop state in
      (match v_list with
       | VList arr ->
           let new_arr = Array.append !arr [|item|] in
           arr := new_arr;
           push state VNull
       | _ -> raise (Runtime_error "List.append expects a list"))
  | "Map.size", 1 ->
      let v = pop state in
      (match v with
       | VMap m -> push state (VInt (Hashtbl.length m))
       | _ -> raise (Runtime_error "Map.size expects a map"))
  | "Map.keys", 1 ->
      let v = pop state in
      (match v with
       | VMap m ->
           let keys = Hashtbl.fold (fun k _ acc -> VString k :: acc) m [] in
           push state (VList (ref (Array.of_list keys)))
       | _ -> raise (Runtime_error "Map.keys expects a map"))
  | _ -> raise (Runtime_error ("Unknown builtin: " ^ name))

let rec run state =
  while not state.halted && state.ip < Array.length state.instructions do
    let instr = state.instructions.(state.ip) in
    state.ip <- state.ip + 1;
    execute_instr state instr
  done

and execute_instr state = function
  | IConstInt n -> push state (VInt n)
  | IConstFloat f -> push state (VFloat f)
  | IConstString s -> push state (VString s)
  | IConstBool b -> push state (VBool b)
  | IConstNull -> push state VNull
  
  | ILoad name ->
      (match lookup state name with
       | Some v -> push state v
       | None -> 
           if name = "Net.get" || name = "print" || name = "str" || 
              String.starts_with ~prefix:"List." name || 
              String.starts_with ~prefix:"Map." name then
              () (* Handled by ICall *)
           else
              raise (Runtime_error ("Undefined variable: " ^ name)))
              
  | IStore name ->
      let v = pop state in
      store state name v
      
  | IDefine name ->
      let v = pop state in
      Hashtbl.replace (List.hd state.scopes) name v

  | ILoadIndex ->
      let idx = pop state in
      let container = pop state in
      (match container, idx with
       | VMap m, VString key -> 
           push state (match Hashtbl.find_opt m key with Some v -> v | None -> VNull)
       | VList arr, VInt i ->
           if i >= 0 && i < Array.length !arr then
             push state (!arr).(i)
           else
             raise (Runtime_error "Index out of bounds")
       | _ -> raise (Runtime_error "Invalid index access"))
       
  | ILoadMember m ->
      let container = pop state in
      (match container with
       | VMap map -> 
           push state (match Hashtbl.find_opt map m with Some v -> v | None -> VNull)
       | VList arr ->
           (match m with
            | "length" -> push state (VInt (Array.length !arr))
            | _ -> raise (Runtime_error ("Invalid list member: " ^ m)))
       | _ -> raise (Runtime_error "Invalid member access"))

  | IBinOp op ->
      let v2 = pop state in
      let v1 = pop state in
      push state (apply_binop op v1 v2)
      
  | IUnOp op ->
      let v = pop state in
      push state (apply_unop op v)
      
  | ICall (name, argc) ->
      if name = "print" || name = "str" || name = "Net.get" ||
         String.starts_with ~prefix:"List." name || 
         String.starts_with ~prefix:"Map." name then
        handle_builtin state name argc
      else
        (match Hashtbl.find_opt state.labels name with
         | Some target ->
             let frame = { return_ip = state.ip; saved_scopes = state.scopes } in
             state.call_stack <- frame :: state.call_stack;
             state.ip <- target
         | None -> raise (Runtime_error ("Function not found: " ^ name)))

  | IList n ->
      let elts = Array.make n VNull in
      for i = n - 1 downto 0 do
        elts.(i) <- pop state
      done;
      push state (VList (ref elts))

  | IMap n ->
      let m = Hashtbl.create n in
      for _ = 1 to n do
        let v = pop state in
        let k = pop state in
        match k with
        | VString key -> Hashtbl.add m key v
        | _ -> raise (Runtime_error "Map key must be a string")
      done;
      push state (VMap m)

  | ITuple n ->
      let elts = Array.make n VNull in
      for i = n - 1 downto 0 do
        elts.(i) <- pop state
      done;
      push state (VList (ref elts)) (* For now, tuples are lists *)
      
  | IReturn ->
      (match state.call_stack with
       | frame :: rest ->
           state.ip <- frame.return_ip;
           state.scopes <- frame.saved_scopes;
           state.call_stack <- rest
       | [] -> state.halted <- true)
       
  | IJump label ->
      state.ip <- Hashtbl.find state.labels label
      
  | IJumpIfFalse label ->
      let v = pop state in
      if v = VBool false || v = VNull then
        state.ip <- Hashtbl.find state.labels label
        
  | IJumpIfTrue label ->
      let v = pop state in
      if v <> VBool false && v <> VNull then
        state.ip <- Hashtbl.find state.labels label
        
  | IPushScope ->
      state.scopes <- Hashtbl.create 10 :: state.scopes
      
  | IPopScope ->
      (match state.scopes with
       | _ :: rest when rest <> [] -> state.scopes <- rest
       | _ -> ())
       
  | ILabel _ -> ()
  | IHalt -> state.halted <- true
  | IThrow -> raise (Runtime_error "Exception thrown")
  
  | IStoreIndex ->
      let v = pop state in
      let idx = pop state in
      let container = pop state in
      (match container, idx with
       | VMap m, VString key -> Hashtbl.replace m key v
       | VList arr, VInt i ->
           if i >= 0 && i < Array.length !arr then
             (!arr).(i) <- v
           else
             raise (Runtime_error "Index out of bounds")
       | _ -> raise (Runtime_error "Invalid index access"))
       
  | IStoreMember m ->
      let v = pop state in
      let container = pop state in
      (match container with
       | VMap map -> Hashtbl.replace map m v
       | _ -> raise (Runtime_error "Invalid member access"))

and apply_binop op v1 v2 =
  match op, v1, v2 with
  | Add, VInt a, VInt b -> VInt (a + b)
  | Add, VString a, VString b -> VString (a ^ b)
  | Add, VString a, v -> VString (a ^ string_of_value v)
  | Add, v, VString b -> VString (string_of_value v ^ b)
  | Sub, VInt a, VInt b -> VInt (a - b)
  | Mul, VInt a, VInt b -> VInt (a * b)
  | Div, VInt a, VInt b -> VInt (if b <> 0 then a / b else raise (Runtime_error "Div by zero"))
  | Eq, _, _ -> VBool (v1 = v2)
  | Ne, _, _ -> VBool (v1 <> v2)
  | Lt, VInt a, VInt b -> VBool (a < b)
  | Gt, VInt a, VInt b -> VBool (a > b)
  | Le, VInt a, VInt b -> VBool (a <= b)
  | Ge, VInt a, VInt b -> VBool (a >= b)
  | Mod, VInt a, VInt b -> VInt (if b <> 0 then a mod b else raise (Runtime_error "Mod by zero"))
  | _ -> raise (Runtime_error "Operation not supported")

and apply_unop op v =
  match op, v with
  | Neg, VInt n -> VInt (-n)
  | Not, VBool b -> VBool (not b)
  | _ -> raise (Runtime_error "Operation not supported")
