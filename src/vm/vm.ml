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
  mutable sockets : (int, Unix.file_descr) Hashtbl.t;
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
    sockets = Hashtbl.create 10;
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

let rec json_of_value = function
  | VInt n -> string_of_int n
  | VFloat f -> string_of_float f
  | VString s -> "\"" ^ String.escaped s ^ "\""
  | VBool b -> string_of_bool b
  | VNull -> "null"
  | VMap m -> 
      let pairs = Hashtbl.fold (fun k v acc -> ("\"" ^ String.escaped k ^ "\": " ^ json_of_value v) :: acc) m [] in
      "{" ^ String.concat ", " pairs ^ "}"
  | VList arr -> 
      let elts = Array.to_list !arr in
      "[" ^ String.concat ", " (List.map json_of_value elts) ^ "]"

let parse_json s =
  let s = String.trim s in
  let rec parse_val i =
    let i = skip_ws i in
    if i >= String.length s then (VNull, i)
    else match s.[i] with
    | '{' -> parse_map (i + 1)
    | '[' -> parse_list (i + 1)
    | '"' -> parse_string (i + 1)
    | 't' when String.sub s i 4 = "true" -> (VBool true, i + 4)
    | 'f' when String.sub s i 5 = "false" -> (VBool false, i + 5)
    | 'n' when String.sub s i 4 = "null" -> (VNull, i + 4)
    | c when (c >= '0' && c <= '9') || c = '-' -> parse_num i
    | _ -> (VNull, i + 1)
  and skip_ws i = if i < String.length s && (s.[i] = ' ' || s.[i] = '\n' || s.[i] = '\t' || s.[i] = '\r') then skip_ws (i + 1) else i
  and parse_string i =
    let start = i in
    let rec find_end i =
      if i >= String.length s then i
      else if s.[i] = '"' && (i = 0 || s.[i-1] <> '\\') then i
      else find_end (i + 1)
    in
    let e = find_end i in
    (VString (String.sub s start (e - start)), e + 1)
  and parse_num i =
    let start = i in
    let rec find_end i =
      if i < String.length s && ((s.[i] >= '0' && s.[i] <= '9') || s.[i] = '.' || s.[i] = '-') then find_end (i + 1) else i
    in
    let e = find_end i in
    let num_s = String.sub s start (e - start) in
    if String.contains num_s '.' then (VFloat (float_of_string num_s), e) else (VInt (int_of_string num_s), e)
  and parse_list i =
    let elts = ref [] in
    let rec loop i =
      let i = skip_ws i in
      if i < String.length s && s.[i] = ']' then (VList (ref (Array.of_list (List.rev !elts))), i + 1)
      else
        let (v, next_i) = parse_val i in
        elts := v :: !elts;
        let next_i = skip_ws next_i in
        if next_i < String.length s && s.[next_i] = ',' then loop (next_i + 1) else loop next_i
    in loop i
  and parse_map i =
    let m = Hashtbl.create 10 in
    let rec loop i =
      let i = skip_ws i in
      if i < String.length s && s.[i] = '}' then (VMap m, i + 1)
      else
        let (k_val, next_i) = parse_val i in
        let key = match k_val with VString k -> k | _ -> string_of_value k_val in
        let next_i = skip_ws next_i in
        let next_i = if next_i < String.length s && s.[next_i] = ':' then next_i + 1 else next_i in
        let next_i = skip_ws next_i in
        let (v, next_i) = parse_val next_i in
        Hashtbl.add m key v;
        let next_i = skip_ws next_i in
        if next_i < String.length s && s.[next_i] = ',' then loop (next_i + 1) else loop next_i
    in loop i
  in
  let (v, _) = parse_val 0 in v

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
  | "Net.listen", 1 ->
      let port_val = pop state in
      (match port_val with
       | VInt port ->
           let s = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
           Unix.setsockopt s Unix.SO_REUSEADDR true;
           let addr = Unix.ADDR_INET (Unix.inet_addr_any, port) in
           Unix.bind s addr;
           Unix.listen s 10;
           let handle = Random.int 1000000 in
           Hashtbl.add state.sockets handle s;
           push state (VInt handle)
       | _ -> raise (Runtime_error "Net.listen expects integer port"))
  | "Net.accept", 1 ->
      let handle_val = pop state in
      (match handle_val with
       | VInt h ->
           let s = Hashtbl.find state.sockets h in
           let (client_sock, _) = Unix.accept s in
           let client_h = Random.int 1000000 in
           Hashtbl.add state.sockets client_h client_sock;
           push state (VInt client_h)
       | _ -> raise (Runtime_error "Invalid socket handle"))
  | "Net.readRequest", 1 ->
      let h_val = pop state in
      (match h_val with
       | VInt h ->
           let s = Hashtbl.find state.sockets h in
           let buf = Bytes.create 4096 in
           let len = Unix.read s buf 0 4096 in
           let raw = Bytes.sub_string buf 0 len in
           (* Initial simple parsing: Method Path HTTP/...\r\n... *)
           let parts = Str.split (Str.regexp "[ \r\n]+") raw in
           let method_ = if List.length parts > 0 then List.nth parts 0 else "GET" in
           let path = if List.length parts > 1 then List.nth parts 1 else "/" in
           let m = Hashtbl.create 5 in
           Hashtbl.add m "method" (VString method_);
           Hashtbl.add m "path" (VString path);
           Hashtbl.add m "body" (VString ""); 
           push state (VMap m)
       | _ -> raise (Runtime_error "Net.readRequest expects socket handle"))
  | "Net.sendResponse", 2 ->
      let res_val = pop state in
      let h_val = pop state in
      (match h_val, res_val with
       | VInt h, VMap m ->
           let s = Hashtbl.find state.sockets h in
           let status = match Hashtbl.find_opt m "status" with Some(VInt i) -> i | _ -> 200 in
           let body = match Hashtbl.find_opt m "body" with Some(VString s) -> s | _ -> "" in
           let response = Printf.sprintf "HTTP/1.1 %d OK\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s" status (String.length body) body in
           let _ = Unix.write_substring s response 0 (String.length response) in
           Unix.close s; (* Close connection after sending *)
           Hashtbl.remove state.sockets h;
           push state VNull
       | _ -> raise (Runtime_error "Net.sendResponse expects (handle, responseMap)"))
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
  | "typeOf", 1 | "Sys.typeOf", 1 ->
      let v = pop state in
      let t = match v with
        | VInt _ -> "Integer" | VFloat _ -> "Float"
        | VString _ -> "String" | VBool _ -> "Bool"
        | VNull -> "Null" | VMap _ -> "Map" | VList _ -> "Array"
      in
      push state (VString t)
  | "panic", 1 | "Sys.panic", 1 ->
      let v = pop state in
      raise (Runtime_error (string_of_value v))
  | "toString", 1 | "Sys.toString", 1 ->
      let v = pop state in
      push state (VString (string_of_value v))
  | "toInt", 1 | "Sys.toInt", 1 ->
      let v = pop state in
      (match v with
       | VInt n -> push state (VInt n)
       | VFloat f -> push state (VInt (int_of_float f))
       | VString s -> (try push state (VInt (int_of_string s)) with _ -> raise (Runtime_error "Cannot convert to Int"))
       | _ -> raise (Runtime_error "Cannot convert to Int"))
  | "toFloat", 1 | "Sys.toFloat", 1 ->
      let v = pop state in
      (match v with
       | VInt n -> push state (VFloat (float_of_int n))
       | VFloat f -> push state (VFloat f)
       | VString s -> (try push state (VFloat (float_of_string s)) with _ -> raise (Runtime_error "Cannot convert to Float"))
       | _ -> raise (Runtime_error "Cannot convert to Float"))
  | "toBool", 1 | "Sys.toBool", 1 ->
      let v = pop state in
      (match v with
       | VBool b -> push state (VBool b)
       | VInt n -> push state (VBool (n <> 0))
       | VNull -> push state (VBool false)
       | _ -> push state (VBool true))
  | "Maths.floor", 1 -> let v = pop state in (match v with VFloat f -> push state (VInt (int_of_float (floor f))) | _ -> raise (Runtime_error "Float expected"))
  | "Maths.ceil", 1 -> let v = pop state in (match v with VFloat f -> push state (VInt (int_of_float (ceil f))) | _ -> raise (Runtime_error "Float expected"))
  | "Maths.sqrt", 1 -> let v = pop state in (match v with VFloat f -> push state (VFloat (sqrt f)) | _ -> raise (Runtime_error "Float expected"))
  | "Maths.sin", 1 -> let v = pop state in (match v with VFloat f -> push state (VFloat (sin f)) | _ -> raise (Runtime_error "Float expected"))
  | "Maths.cos", 1 -> let v = pop state in (match v with VFloat f -> push state (VFloat (cos f)) | _ -> raise (Runtime_error "Float expected"))
  | "Maths.tan", 1 -> let v = pop state in (match v with VFloat f -> push state (VFloat (tan f)) | _ -> raise (Runtime_error "Float expected"))
  | "Maths.asin", 1 -> let v = pop state in (match v with VFloat f -> push state (VFloat (asin f)) | _ -> raise (Runtime_error "Float expected"))
  | "Maths.acos", 1 -> let v = pop state in (match v with VFloat f -> push state (VFloat (acos f)) | _ -> raise (Runtime_error "Float expected"))
  | "Maths.atan", 1 -> let v = pop state in (match v with VFloat f -> push state (VFloat (atan f)) | _ -> raise (Runtime_error "Float expected"))
  | "Maths.log", 1 -> let v = pop state in (match v with VFloat f -> push state (VFloat (log f)) | _ -> raise (Runtime_error "Float expected"))
  | "Maths.log10", 1 -> let v = pop state in (match v with VFloat f -> push state (VFloat (log10 f)) | _ -> raise (Runtime_error "Float expected"))
  | "Maths.exp", 1 -> let v = pop state in (match v with VFloat f -> push state (VFloat (exp f)) | _ -> raise (Runtime_error "Float expected"))
  | "Maths.random", 0 -> push state (VFloat (Random.float 1.0))
  | "String.length", 1 ->
      let v = pop state in
      (match v with
       | VString s -> push state (VInt (String.length s))
       | _ -> raise (Runtime_error "String.length expects a string"))
  | "String.slice", 3 ->
      let endIdx = pop state in
      let start = pop state in
      let s = pop state in
      (match s, start, endIdx with
       | VString s, VInt st, VInt en ->
           let len = String.length s in
           let st = max 0 (min len st) in
           let en = max st (min len en) in
           push state (VString (String.sub s st (en - st)))
       | _ -> raise (Runtime_error "String.slice expects (string, int, int)"))
  | "String.split", 2 ->
      let sep = pop state in
      let s = pop state in
      (match s, sep with
       | VString s, VString sep ->
           let parts = if sep = "" then
                         List.init (String.length s) (fun i -> VString (String.make 1 s.[i]))
                       else
                         let re = Str.regexp_string sep in
                         List.map (fun p -> VString p) (Str.split re s)
           in
           push state (VList (ref (Array.of_list parts)))
       | _ -> raise (Runtime_error "String.split expects two strings"))
  | "String.indexOf", 2 ->
      let sub = pop state in
      let s = pop state in
      (match s, sub with
       | VString s, VString sub ->
           (try push state (VInt (Str.search_forward (Str.regexp_string sub) s 0))
            with Not_found -> push state (VInt (-1)))
       | _ -> raise (Runtime_error "String.indexOf expects two strings"))
  | "String.lastIndexOf", 2 ->
      let sub = pop state in
      let s = pop state in
      (match s, sub with
       | VString s, VString sub ->
           (try push state (VInt (Str.search_backward (Str.regexp_string sub) s (String.length s - 1)))
            with Not_found -> push state (VInt (-1)))
       | _ -> raise (Runtime_error "String.lastIndexOf expects two strings"))
  | "String.replace", 3 ->
      let replacement = pop state in
      let target = pop state in
      let s = pop state in
      (match s, target, replacement with
       | VString s, VString t, VString r ->
           let re = Str.regexp_string t in
           let res = try Str.replace_first re r s with Not_found -> s in
           push state (VString res)
       | _ -> raise (Runtime_error "String.replace expects three strings"))
  | "String.replaceAll", 3 ->
      let replacement = pop state in
      let target = pop state in
      let s = pop state in
      (match s, target, replacement with
       | VString s, VString t, VString r ->
           let re = Str.regexp_string t in
           let res = try Str.global_replace re r s with Not_found -> s in
           push state (VString res)
       | _ -> raise (Runtime_error "String.replaceAll expects three strings"))
  | "String.upper", 1 ->
      let v = pop state in
      (match v with
       | VString s -> push state (VString (String.uppercase_ascii s))
       | _ -> raise (Runtime_error "String.upper expects a string"))
  | "String.lower", 1 ->
      let v = pop state in
      (match v with
       | VString s -> push state (VString (String.lowercase_ascii s))
       | _ -> raise (Runtime_error "String.lower expects a string"))
  | "String.trim", 1 ->
      let v = pop state in
      (match v with
       | VString s -> push state (VString (String.trim s))
       | _ -> raise (Runtime_error "String.trim expects a string"))
  (* Crypto Implementations using openssl CLI *)
  | "Sys.sha256", 1 ->
      let v = pop state in
      let s = string_of_value v in
      let cmd = Printf.sprintf "echo -n \"%s\" | openssl dgst -sha256 -r | awk '{print $1}'" s in
      let ic = Unix.open_process_in cmd in
      let hash = input_line ic in
      let _ = Unix.close_process_in ic in
      push state (VString (String.trim hash))
  | "Sys.sha512", 1 ->
      let v = pop state in
      let s = string_of_value v in
      let cmd = Printf.sprintf "echo -n \"%s\" | openssl dgst -sha512 -r | awk '{print $1}'" s in
      let ic = Unix.open_process_in cmd in
      let hash = input_line ic in
      let _ = Unix.close_process_in ic in
      push state (VString (String.trim hash))
  | "Sys.keccak256", 1 ->
      let v = pop state in
      let s = string_of_value v in
      (* keccak-256 is often not in default openssl, using sha3-256 as proxy or failing if not present *)
      (* For reliable behavior without complex deps, we'll map to sha3-256 which is close enough for placeholder *)
      let cmd = Printf.sprintf "echo -n \"%s\" | openssl dgst -sha3-256 -r | awk '{print $1}'" s in
      let ic = Unix.open_process_in cmd in
      let hash = input_line ic in
      let _ = Unix.close_process_in ic in
      push state (VString (String.trim hash))
  | "Sys.hmacSha256", 2 ->
      let secret = pop state in
      let data = pop state in
      let s_data = string_of_value data in
      let s_secret = string_of_value secret in
      let tmp_data = Filename.temp_file "hmac_data" ".txt" in
      let oc = open_out tmp_data in output_string oc s_data; close_out oc;
      let cmd = Printf.sprintf "openssl dgst -sha256 -hmac \"%s\" -r %s | awk '{print $1}'" (String.escaped s_secret) tmp_data in
      let ic = Unix.open_process_in cmd in
      let hash = try input_line ic with _ -> "" in
      let _ = Unix.close_process_in ic in
      (try Sys.remove tmp_data with _ -> ());
      push state (VString (String.trim hash))
  | "Sys.call", 2 ->
      let args_val = pop state in
      let name_val = pop state in
      (match name_val, args_val with
       | VString name, VList arg_vals_ref ->
           (match Hashtbl.find_opt state.labels name with
            | Some target ->
                 (* Push args onto stack in order so they are popped correctly by callee (last arg on top) *)
                 let arg_vals = !arg_vals_ref in
                 Array.iter (push state) arg_vals;
                 
                 (* Create stack frame and jump *)
                 let frame = { return_ip = state.ip; saved_scopes = state.scopes } in
                 state.call_stack <- frame :: state.call_stack;
                 state.ip <- target
            | None -> raise (Runtime_error ("Function not found: " ^ name)))
       | _ -> raise (Runtime_error "Sys.call expects (functionName: String, args: List)"))
  | "Sys.randomBytes", 1 ->
      let v = pop state in
      (match v with
       | VInt n ->
           let elts = Array.make n VNull in
           for i = 0 to n - 1 do
             elts.(i) <- VInt (Random.int 256)
           done;
           push state (VList (ref elts))
       | _ -> raise (Runtime_error "Sys.randomBytes expects an integer"))
  | "Sys.hexEncode", 1 ->
     let v = pop state in
     (match v with
      | VList arr ->
          let s = ref "" in
          Array.iter (fun b -> 
            match b with 
            | VInt i -> s := !s ^ Printf.sprintf "%02x" i
            | _ -> s := !s ^ "00"
          ) !arr;
          push state (VString !s)
      | _ -> raise (Runtime_error "Sys.hexEncode expects a list"))
  | "Sys.sign", 2 ->
      let priv_val = pop state in
      let msg_val = pop state in
      let priv = string_of_value priv_val in
      let msg = string_of_value msg_val in
      let tmp_msg = Filename.temp_file "msg" ".txt" in
      let tmp_key = Filename.temp_file "key" ".pem" in
      let tmp_sig = Filename.temp_file "sig" ".bin" in
      let oc_msg = open_out tmp_msg in output_string oc_msg msg; close_out oc_msg;
      let oc_key = open_out tmp_key in output_string oc_key priv; close_out oc_key;
      let _ = Sys.command (Printf.sprintf "openssl dgst -sha256 -sign %s -out %s %s 2>/dev/null" tmp_key tmp_sig tmp_msg) in
      let cmd_b64 = Printf.sprintf "base64 -w 0 < %s" tmp_sig in
      let ic = Unix.open_process_in cmd_b64 in
      let sig_str = try input_line ic with End_of_file -> "" in
      let _ = Unix.close_process_in ic in
      (try Sys.remove tmp_msg with _ -> ()); (try Sys.remove tmp_key with _ -> ()); (try Sys.remove tmp_sig with _ -> ());
      push state (VString sig_str)
  | "Sys.verify", 3 ->
      let pub_val = pop state in
      let sig_val = pop state in
      let msg_val = pop state in
      let pub = string_of_value pub_val in
      let signature = string_of_value sig_val in
      let msg = string_of_value msg_val in
      let tmp_msg = Filename.temp_file "msg" ".txt" in
      let tmp_pub = Filename.temp_file "pub" ".pem" in
      let tmp_sig = Filename.temp_file "sig" ".bin" in
      let oc_msg = open_out tmp_msg in output_string oc_msg msg; close_out oc_msg;
      let oc_pub = open_out tmp_pub in output_string oc_pub pub; close_out oc_pub;
      let cmd_sig = Printf.sprintf "echo -n \"%s\" | base64 -d > %s 2>/dev/null" signature tmp_sig in
      let _ = Sys.command cmd_sig in
      let cmd_verify = Printf.sprintf "openssl dgst -sha256 -verify %s -signature %s %s 2>/dev/null" tmp_pub tmp_sig tmp_msg in
      let exit_code = Sys.command cmd_verify in
      (try Sys.remove tmp_msg with _ -> ()); (try Sys.remove tmp_pub with _ -> ()); (try Sys.remove tmp_sig with _ -> ());
      push state (VBool (exit_code = 0))
  | "Sys.encrypt", 2 ->
      let key_val = pop state in
      let data_val = pop state in
      let key = string_of_value key_val in
      let data = string_of_value data_val in
      let tmp_in = Filename.temp_file "enc_in" ".txt" in
      let oc = open_out tmp_in in output_string oc data; close_out oc;
      let cmd = Printf.sprintf "openssl enc -aes-256-cbc -a -salt -pass pass:\"%s\" -in %s 2>/dev/null" key tmp_in in
      let ic = Unix.open_process_in cmd in
      let result = ref "" in
      (try while true do result := !result ^ input_line ic ^ "\n" done with End_of_file -> ());
      let _ = Unix.close_process_in ic in
      (try Sys.remove tmp_in with _ -> ());
      push state (VString (String.trim !result))
  | "Sys.decrypt", 2 ->
      let key_val = pop state in
      let data_val = pop state in
      let key = string_of_value key_val in
      let data = string_of_value data_val in
      let tmp_in = Filename.temp_file "dec_in" ".txt" in
      let oc = open_out tmp_in in output_string oc data; close_out oc;
      let cmd = Printf.sprintf "openssl enc -aes-256-cbc -d -a -pass pass:\"%s\" -in %s 2>/dev/null" key tmp_in in
      let ic = Unix.open_process_in cmd in
      let result = ref "" in
      (try while true do result := !result ^ input_line ic ^ "\n" done with End_of_file -> ());
      let _ = Unix.close_process_in ic in
      (try Sys.remove tmp_in with _ -> ());
      push state (VString (String.trim !result))
  | "Sys.genKeyPair", 0 ->
      let tmp_key = Filename.temp_file "key" ".pem" in
      let tmp_pub = Filename.temp_file "pub" ".pem" in
      let _ = Sys.command (Printf.sprintf "openssl genpkey -algorithm RSA -out %s 2>/dev/null" tmp_key) in
      let _ = Sys.command (Printf.sprintf "openssl rsa -in %s -pubout -out %s 2>/dev/null" tmp_key tmp_pub) in
      let read_file f = 
        try
          let ic = open_in f in 
          let n = in_channel_length ic in 
          let s = really_input_string ic n in 
          close_in ic; s 
        with _ -> ""
      in
      let priv = read_file tmp_key in
      let pub = read_file tmp_pub in
      (try Sys.remove tmp_key with _ -> ()); (try Sys.remove tmp_pub with _ -> ());
      let m = Hashtbl.create 2 in
      Hashtbl.add m "private" (VString priv);
      Hashtbl.add m "public" (VString pub);
      push state (VMap m)
  | "Sys.getPublicKey", 1 ->
      let priv_val = pop state in
      let priv = string_of_value priv_val in
      let tmp_key = Filename.temp_file "key" ".pem" in
      let tmp_pub = Filename.temp_file "pub" ".pem" in
      let oc_key = open_out tmp_key in output_string oc_key priv; close_out oc_key;
      let _ = Sys.command (Printf.sprintf "openssl rsa -in %s -pubout -out %s 2>/dev/null" tmp_key tmp_pub) in
      let read_file f = 
        try
          let ic = open_in f in 
          let n = in_channel_length ic in 
          let s = really_input_string ic n in 
          close_in ic; s 
        with _ -> ""
      in
      let pub = read_file tmp_pub in
      (try Sys.remove tmp_key with _ -> ()); (try Sys.remove tmp_pub with _ -> ());
      push state (VString pub)
  | "Sys.writeFile", 2 ->
      let content_val = pop state in
      let path_val = pop state in
      let path = string_of_value path_val in
      let content = string_of_value content_val in
      let oc = open_out path in
      output_string oc content;
      close_out oc;
      push state VNull
  | "Sys.readFile", 1 ->
      let path_val = pop state in
      let path = string_of_value path_val in
      let ic = open_in path in
      let n = in_channel_length ic in
      let s = really_input_string ic n in
      close_in ic;
      push state (VString s)
  | "Sys.deleteFile", 1 ->
      let path_val = pop state in
      let path = string_of_value path_val in
      Sys.remove path;
      push state VNull
  | "Sys.mkdir", 1 ->
      let path_val = pop state in
      let path = string_of_value path_val in
      let _ = Sys.command (Printf.sprintf "mkdir -p \"%s\"" path) in
      push state VNull
  | "Sys.ls", 1 ->
      let path_val = pop state in
      let path = string_of_value path_val in
      let cmd = Printf.sprintf "ls \"%s\"" path in
      let ic = Unix.open_process_in cmd in
      let lines = ref [] in
      (try while true do lines := input_line ic :: !lines done with End_of_file -> ());
      let _ = Unix.close_process_in ic in
      push state (VList (ref (Array.of_list (List.map (fun s -> VString s) (List.rev !lines)))))
  | "Sys.fileExists", 1 ->
      let path_val = pop state in
      let path = string_of_value path_val in
      push state (VBool (Sys.file_exists path))
  | "Sys.now", 0 ->
      push state (VInt (int_of_float (Unix.time ())))
  | "Sys.sleep", 1 ->
      let v = pop state in
      let s = match v with VFloat f -> f | VInt n -> float_of_int n | _ -> 0.0 in
      let _ = Unix.sleepf s in
      push state VNull
  | "Sys.jsonStringify", 1 ->
      let v = pop state in
      push state (VString (json_of_value v))
  | "Sys.getenv", 1 ->
      let v = pop state in
      let k = string_of_value v in
      (try push state (VString (Sys.getenv k)) with Not_found -> push state (VString ""))
  | "Sys.setenv", 2 ->
      let v_val = pop state in
      let k_val = pop state in
      let k = string_of_value k_val in
      let v = string_of_value v_val in
      Unix.putenv k v;
      push state VNull
  | "Sys.exit", 1 ->
      let v = pop state in
      let code = match v with VInt n -> n | _ -> 0 in
      exit code
  | "Sys.jsonParse", 1 ->
      let v = pop state in
      let s = string_of_value v in
      push state (parse_json s)
  | "Sys.date", 1 ->
      let format_val = pop state in
      let fmt = string_of_value format_val in
      let cmd = Printf.sprintf "date +\"%s\"" fmt in
      let ic = Unix.open_process_in cmd in
      let res = input_line ic in
      let _ = Unix.close_process_in ic in
      push state (VString res)
  | "Sys.base64Encode", 1 ->
      let v = pop state in
      let s = string_of_value v in
      let tmp_in = Filename.temp_file "b64_in" ".txt" in
      let oc = open_out tmp_in in output_string oc s; close_out oc;
      let cmd = Printf.sprintf "base64 -w 0 < %s" tmp_in in
      let ic = Unix.open_process_in cmd in
      let res = try input_line ic with _ -> "" in
      let _ = Unix.close_process_in ic in
      (try Sys.remove tmp_in with _ -> ());
      push state (VString res)
  | "Sys.base64Decode", 1 ->
      let v = pop state in
      let s = string_of_value v in
      let tmp_in = Filename.temp_file "b64_dec_in" ".txt" in
      let oc = open_out tmp_in in output_string oc s; close_out oc;
      let cmd = Printf.sprintf "base64 -d < %s" tmp_in in
      let ic = Unix.open_process_in cmd in
      let b = Buffer.create 1024 in
      (try while true do Buffer.add_channel b ic 1 done with End_of_file -> ());
      let _ = Unix.close_process_in ic in
      (try Sys.remove tmp_in with _ -> ());
      push state (VString (Buffer.contents b))
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
              name = "typeOf" || name = "panic" || name = "toString" ||
              name = "toInt" || name = "toFloat" || name = "toBool" ||
              String.starts_with ~prefix:"Sys." name ||
              String.starts_with ~prefix:"Net." name ||
              String.starts_with ~prefix:"List." name || 
              String.starts_with ~prefix:"Map." name ||
              String.starts_with ~prefix:"String." name ||
              String.starts_with ~prefix:"Maths." name then
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
         name = "typeOf" || name = "panic" ||
         name = "toString" || name = "toInt" || name = "toFloat" || name = "toBool" ||
         String.starts_with ~prefix:"Sys." name ||
         String.starts_with ~prefix:"Net." name ||
         String.starts_with ~prefix:"List." name || 
         String.starts_with ~prefix:"Map." name ||
         String.starts_with ~prefix:"String." name ||
         String.starts_with ~prefix:"Maths." name then
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
        
  | INew(class_name, argc) ->
      (* Pop constructor arguments *)
      let _args = ref [] in
      for _ = 1 to argc do
        _args := pop state :: !_args
      done;
      (* Create a new instance as a map for now *)
      let instance = Hashtbl.create 10 in
      Hashtbl.add instance "__type__" (VString class_name);
      
      (* TODO: Call constructor if it exists *)
      (* For now, we assume fields are initialized via default or not at all *)
      
      push state (VMap instance)

  | IMethodCall(method_name, argc) ->
      (* 1. Identify valid object *)
      (* Stack: [Arg1...ArgN, Obj] (Obj is at index N) *)
      let obj_val = try List.nth state.stack argc 
                    with _ -> raise (Runtime_error "Stack underflow in method call") in
      
      let class_name, is_primitive = match obj_val with
        | VMap headers ->
            (match Hashtbl.find_opt headers "__type__" with
             | Some (VString s) -> s, false
             | _ -> "Map", true)
        | VList _ -> "List", true
        | VString _ -> "String", true
        | VInt _ -> "Integer", true
        | VFloat _ -> "Float", true
        | _ -> "", false
      in
      
      if is_primitive || (class_name = "Map" && is_primitive) then (
          let full_name = class_name ^ "." ^ method_name in
          (* Call builtin with argc + 1 (including implicit 'this' obj) *)
          handle_builtin state full_name (argc + 1)
      ) else (
          let full_name = class_name ^ "." ^ method_name in
          match Hashtbl.find_opt state.labels full_name with
           | Some target ->
               let frame = { return_ip = state.ip; saved_scopes = state.scopes } in
               state.call_stack <- frame :: state.call_stack;
               state.ip <- target
           | None -> raise (Runtime_error ("Method not found: " ^ full_name))
      )
        
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
  | Add, VFloat a, VFloat b -> VFloat (a +. b)
  | Add, VInt a, VFloat b -> VFloat (float_of_int a +. b)
  | Add, VFloat a, VInt b -> VFloat (a +. float_of_int b)
  | Add, VString a, VString b -> VString (a ^ b)
  | Add, VString a, v -> VString (a ^ string_of_value v)
  | Add, v, VString b -> VString (string_of_value v ^ b)
  | Sub, VInt a, VInt b -> VInt (a - b)
  | Sub, VFloat a, VFloat b -> VFloat (a -. b)
  | Sub, VInt a, VFloat b -> VFloat (float_of_int a -. b)
  | Sub, VFloat a, VInt b -> VFloat (a -. float_of_int b)
  | Mul, VInt a, VInt b -> VInt (a * b)
  | Mul, VFloat a, VFloat b -> VFloat (a *. b)
  | Mul, VInt a, VFloat b -> VFloat (float_of_int a *. b)
  | Mul, VFloat a, VInt b -> VFloat (a *. float_of_int b)
  | Div, VInt a, VInt b -> VInt (if b <> 0 then a / b else raise (Runtime_error "Div by zero"))
  | Div, VFloat a, VFloat b -> VFloat (a /. b)
  | Eq, _, _ -> VBool (v1 = v2)
  | Ne, _, _ -> VBool (v1 <> v2)
  | Lt, VInt a, VInt b -> VBool (a < b)
  | Lt, VFloat a, VFloat b -> VBool (a < b)
  | Gt, VInt a, VInt b -> VBool (a > b)
  | Gt, VFloat a, VFloat b -> VBool (a > b)
  | Le, VInt a, VInt b -> VBool (a <= b)
  | Le, VFloat a, VFloat b -> VBool (a <= b)
  | Ge, VInt a, VInt b -> VBool (a >= b)
  | Ge, VFloat a, VFloat b -> VBool (a >= b)
  | Mod, VInt a, VInt b -> VInt (if b <> 0 then a mod b else raise (Runtime_error "Mod by zero"))
  | Pow, VInt a, VInt b -> VInt (int_of_float (float_of_int a ** float_of_int b))
  | Pow, VFloat a, VFloat b -> VFloat (a ** b)
  | And, VBool a, VBool b -> VBool (a && b)
  | Or, VBool a, VBool b -> VBool (a || b)
  | _ -> 
      let op_str = match op with 
        | Add -> "+" | Sub -> "-" | Mul -> "*" | Div -> "/" | Mod -> "%" | Pow -> "**"
        | Eq -> "==" | Ne -> "!=" | Lt -> "<" | Gt -> ">" | Le -> "<=" | Ge -> ">="
        | And -> "and" | Or -> "or"
      in
      let msg = Printf.sprintf "Operation not supported: binop %s on %s and %s" 
                  op_str (string_of_value v1) (string_of_value v2)
      in
      raise (Runtime_error msg)

and apply_unop op v =
  match op, v with
  | Neg, VInt n -> VInt (-n)
  | Neg, VFloat f -> VFloat (-.f)
  | Not, VBool b -> VBool (not b)
  | _ -> 
      let msg = Printf.sprintf "Operation not supported: unop %s on %s"
                  (match op with Neg -> "-" | Not -> "not")
                  (string_of_value v)
      in
      raise (Runtime_error msg)
