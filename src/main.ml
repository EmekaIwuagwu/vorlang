(* Vorlang Compiler Main Entry Point *)
(* OCaml main module for the Vorlang programming language compiler *)

open Ast
open Tokens
open Lexer
open Parser
open Semantic
open Codegen
open Parser_util

(* Command line arguments *)
type command =
  | Compile of string
  | Run of string
  | Repl
  | Help

(* Parse command line arguments *)
let parse_args () =
  let args = Array.to_list Sys.argv in
  match args with
  | _ :: "compile" :: filename :: _ -> Compile filename
  | _ :: "run" :: filename :: _ -> Run filename
  | _ :: "repl" :: _ -> Repl
  | _ :: "help" :: _ -> Help
  | _ :: "--help" :: _ -> Help
  | _ :: "-h" :: _ -> Help
  | _ -> Help

(* Print help message *)
let print_help () =
  Printf.printf "Vorlang Compiler\n";
  Printf.printf "Usage: vorlang <command> [options]\n";
  Printf.printf "\n";
  Printf.printf "Commands:\n";
  Printf.printf "  compile <file>    Compile a Vorlang file\n";
  Printf.printf "  run <file>        Compile and run a Vorlang file\n";
  Printf.printf "  repl              Start the interactive REPL\n";
  Printf.printf "  help              Show this help message\n";
  Printf.printf "\n";
  Printf.printf "Examples:\n";
  Printf.printf "  vorlang compile hello.vorlang\n";
  Printf.printf "  vorlang run hello.vorlang\n";
  Printf.printf "  vorlang repl\n"

(* Compile a single file *)
let compile_file filename =
  try
    if not (Sys.file_exists filename) then (
      Printf.eprintf "Error: File %s not found\n" filename;
      exit 1
    );
    
    (* Parse the file with imports resolved *)
    let program = parse_file_with_imports filename in
    
    (* Semantic analysis *)
    analyze_program program;
    
    (* Generate bytecode *)
    let bytecode = generate_program program in
    bytecode
    
  with
  | Parse_error msg ->
      Printf.eprintf "Parse error: %s\n" msg;
      exit 1
  | Semantic_error msg ->
      Printf.eprintf "Semantic error: %s\n" msg;
      exit 1
  | Lexer.Lexing_error msg ->
      Printf.eprintf "Lexing error: %s\n" msg;
      exit 1
  | Sys_error msg ->
      Printf.eprintf "File error: %s\n" msg;
      exit 1

(* Run a file (compile and execute) *)
let run_file filename =
  try
    let bytecode = compile_file filename in
    let vm_state = Vm.create_state bytecode in
    Vm.run vm_state
    
  with
  | Vm.Runtime_error msg ->
      Printf.eprintf "Runtime error: %s\n" msg;
      exit 1
  | exn ->
      Printf.eprintf "Unexpected error: %s\n" (Printexc.to_string exn);
      exit 1

(* Start the REPL *)
let start_repl () =
  Printf.printf "Welcome to the Vorlang REPL!\n";
  Printf.printf "Type 'exit' to quit.\n";
  
  let rec loop () =
    Printf.printf "> ";
    let input = read_line () in
    if input = "exit" then
      ()
    else
      try
        (* Parse and analyze the input *)
        let program = parse_string input in
        analyze_program program;
        let bytecode = generate_program program in
        print_bytecode bytecode;
      with
      | Parse_error msg ->
          Printf.eprintf "Parse error: %s\n" msg
      | Semantic_error msg ->
          Printf.eprintf "Semantic error: %s\n" msg
      | Lexer.Lexing_error msg ->
          Printf.eprintf "Lexing error: %s\n" msg
      | exn ->
          Printf.eprintf "Error: %s\n" (Printexc.to_string exn);
      loop ()
  in
  loop ()

(* Main function *)
let main () =
  match parse_args () with
  | Compile filename -> 
      let bytecode = compile_file filename in
      (* For debugging, we re-parse for the AST or we could store it *)
      let program = parse_file_with_imports filename in
      print_program program;
      print_bytecode bytecode;
      Printf.printf "Compilation successful!\n"
  | Run filename -> run_file filename
  | Repl -> start_repl ()
  | Help -> print_help ()

(* Entry point *)
let () = main ()
