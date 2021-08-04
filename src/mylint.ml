open Base

module Level = struct
  type t =
    | Allow
    | Warn
    | Deny
    | Deprecated
end

module Groups = struct
  type t = Style
  (* Correctness Perf Restriction Deprecated Pedantic Complexity Suspicious Cargo Nursery *)
end

open UntypedLints

let all_linters =
  [ (module GuardInsteadOfIf : LINT.S)
  ; (module Casing : LINT.S)
  ; (module ParsetreeHasDocs : LINT.S)
  ]
;;

let build_iterator ~compose ~f =
  let o =
    List.fold_left
      ~f:(fun acc lint -> compose lint acc)
      ~init:Ast_iterator.default_iterator
      all_linters
  in
  f o
;;

let on_structure info =
  build_iterator
    ~f:(fun o -> o.Ast_iterator.structure o)
    ~compose:(fun (module L : LINT.S) -> L.stru info)
;;

let on_signature info =
  build_iterator
    ~f:(fun o -> o.Ast_iterator.signature o)
    ~compose:(fun (module L : LINT.S) -> L.stru info)
;;

let load_file filename =
  Clflags.error_style := Some Misc.Error_style.Contextual;
  let with_info f =
    Compile_common.with_info
      ~native:false
      ~source_file:filename
      ~tool_name:"asdf"
      ~output_prefix:"asdf"
      ~dump_ext:"asdf"
      f
  in
  let () =
    with_info (fun info ->
        if String.equal (String.suffix info.source_file 3) ".ml"
        then (
          let parsetree = Compile_common.parse_impl info in
          on_structure info parsetree)
        else if String.equal (String.suffix info.source_file 4) ".mli"
        then (
          let parsetree = Compile_common.parse_intf info in
          on_signature info parsetree)
        else Format.printf "%s %d\n%!" __FILE__ __LINE__)
  in
  (* Caml.print_endline @@ Pprintast.string_of_structure parsetree; *)
  CollectedLints.report ();
  CollectedLints.clear ();
  (* let tstr, _coe = with_info (fun info -> Compile_common.typecheck_impl info parsetree) in *)
  (* Format.printf "%a\n%!" Printtyped.implementation tstr; *)
  ()
;;

let () =
  let open Config in
  Arg.parse
    [ "-o", Arg.String Options.set_out_file, "Set Markdown output file"
    ; "-ogolint", Arg.String Options.set_out_golint, "Set output file in golint format"
    ; "-ordjsonl", Arg.String Options.set_out_rdjsonl, "Set output file in rdjsonl format"
    ; "-ws", Arg.String Options.set_workspace, "Set dune workspace root"
    ; ( "-del-prefix"
      , Arg.String Options.set_prefix_to_cut
      , "Set prefix to cut from file names" )
    ; ( "-add-prefix"
      , Arg.String Options.set_prefix_to_add
      , "Set prefix to reprend to file names" )
    ; ( "-dump-lints"
      , Arg.String Options.set_dump_file
      , "Dump information about available linters to JSON" )
    ]
    Options.set_in_file
    "usage";
  let () =
    match Options.dump_file () with
    | None -> ()
    | Some filename ->
      let info =
        List.map all_linters ~f:(fun (module L : LINT.S) -> L.describe_itself ())
      in
      let ch = Caml.open_out filename in
      Exn.protect
        ~f:(fun () -> Yojson.Safe.pretty_to_channel ~std:true ch (`List info))
        ~finally:(fun () -> Caml.close_out ch);
      Caml.exit 0
  in
  load_file (Options.infile ())
;;
