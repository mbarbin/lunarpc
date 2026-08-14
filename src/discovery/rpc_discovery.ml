(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module App_name = App_name
module Discovery_file = Discovery_file
module Instance_name = Instance_name
module Service_id = Service_id
module Service_name = Service_name

module Discovery_via_file = struct
  type t = { root_directory : Absolute_path.t }

  let equal t1 ({ root_directory } as t2) =
    phys_equal t1 t2 || Absolute_path.equal t1.root_directory root_directory
  ;;
end

module Switch = struct
  let port = "port"
  let discovery_root = "discovery-root"
  let root_directory = "root-directory"
  let port_chosen_by_os = "port-chosen-by-os"
end

module Connection_config = struct
  type t =
    | Tcp of
        { host : [ `Localhost ]
        ; port : int
        }
    | Discovery_via_file of Discovery_via_file.t

  let equal a b =
    match a, b with
    | Tcp { host = `Localhost; port = p1 }, Tcp { host = `Localhost; port = p2 } ->
      Int.equal p1 p2
    | Discovery_via_file a, Discovery_via_file b -> Discovery_via_file.equal a b
    | (Tcp _ | Discovery_via_file _), _ -> false
  ;;

  let arg =
    let open Command.Std in
    let+ by_port =
      Arg.named_opt
        [ Switch.port ]
        Param.int
        ~docv:"PORT"
        ~doc:"Connect to localhost TCP port."
      >>| Option.map ~f:(fun port -> Tcp { host = `Localhost; port })
    and+ by_discovery_root =
      Arg.named_opt
        [ Switch.discovery_root ]
        (Param.validated_string (module Absolute_path))
        ~docv:"PATH"
        ~doc:
          "Use file-based service discovery to find the server. This is the default \
           strategy when no connection option is provided. The server advertises its \
           port in a discovery file under this directory. Defaults to \\$HOME or the \
           current working directory if not specified."
      >>| Option.map ~f:(fun root_directory ->
        Discovery_via_file { Discovery_via_file.root_directory })
    in
    match List.filter_opt [ by_port; by_discovery_root ] with
    | [ spec ] -> spec
    | [] ->
      (* Default to discovery directory with $HOME or cwd *)
      Discovery_via_file { root_directory = Via_file.default_root ~root_directory:None }
    | _ :: _ :: _ ->
      Err.raise
        ~exit_code:Err.Exit_code.cli_error
        [ Pp.text "Only one of --port or --discovery-root can be used." ]
  ;;

  let to_args t =
    match t with
    | Tcp { host = `Localhost; port } -> [ "--" ^ Switch.port; Int.to_string port ]
    | Discovery_via_file { root_directory } ->
      [ "--" ^ Switch.discovery_root; Absolute_path.to_string root_directory ]
  ;;

  let port t ~service_id : int =
    match t with
    | Tcp { host = `Localhost; port } -> port
    | Discovery_via_file { root_directory } ->
      (Via_file.find_server ~root_directory ~service_id ()).port
  ;;
end

let root_directory_arg =
  let open Command.Std in
  let+ root_directory =
    Arg.named_opt
      [ Switch.root_directory ]
      (Param.validated_string (module Absolute_path))
      ~docv:"PATH"
      ~doc:
        "Root directory for service discovery and runtime data. Defaults to \\$HOME or \
         current working directory."
  in
  Via_file.default_root ~root_directory
;;

module Listening_config = struct
  module Specification = struct
    type t = Tcp of { port : [ `Chosen_by_OS | `Supplied of int ] }

    let equal a b =
      match a, b with
      | Tcp { port = `Chosen_by_OS }, Tcp { port = `Chosen_by_OS } -> true
      | Tcp { port = `Supplied p1 }, Tcp { port = `Supplied p2 } -> Int.equal p1 p2
      | Tcp _, Tcp _ -> false
    ;;
  end

  type t =
    { specification : Specification.t
    ; discovery_via_file : Discovery_via_file.t
    }

  let equal t1 ({ specification; discovery_via_file } as t2) =
    phys_equal t1 t2
    || (Specification.equal t1.specification specification
        && Discovery_via_file.equal t1.discovery_via_file discovery_via_file)
  ;;

  let arg =
    let open Command.Std in
    let+ specification =
      let+ by_os =
        let+ chosen_by_os =
          Arg.flag
            [ Switch.port_chosen_by_os ]
            ~doc:"Listen on localhost TCP port chosen by OS (default)."
        in
        if chosen_by_os then Some (Specification.Tcp { port = `Chosen_by_OS }) else None
      and+ by_port =
        Arg.named_opt
          [ Switch.port ]
          Param.int
          ~docv:"PORT"
          ~doc:"Listen on localhost TCP port."
        >>| Option.map ~f:(fun port -> Specification.Tcp { port = `Supplied port })
      in
      match List.filter_opt [ by_os; by_port ] with
      | [ spec ] -> spec
      | [] -> Specification.Tcp { port = `Chosen_by_OS }
      | _ :: _ :: _ ->
        Err.raise
          ~exit_code:Err.Exit_code.cli_error
          [ Pp.text "Only one of --port or --port-chosen-by-os can be used." ]
    and+ root_directory = root_directory_arg in
    let discovery_via_file = { Discovery_via_file.root_directory } in
    { specification; discovery_via_file }
  ;;

  let to_args t =
    let specification =
      match t.specification with
      | Tcp { port = `Chosen_by_OS } -> [ "--" ^ Switch.port_chosen_by_os ]
      | Tcp { port = `Supplied port } -> [ "--" ^ Switch.port; Int.to_string port ]
    in
    let discovery_via_file =
      [ "--" ^ Switch.root_directory
      ; Absolute_path.to_string t.discovery_via_file.root_directory
      ]
    in
    List.concat [ specification; discovery_via_file ]
  ;;

  let port { specification; discovery_via_file = _ } : int =
    match specification with
    | Tcp { port } ->
      (match port with
       | `Supplied port -> port
       | `Chosen_by_OS -> 0)
  ;;

  let advertize t ~service_id ~instance_name ~port =
    Via_file.advertize_server
      ~root_directory:t.discovery_via_file.root_directory
      ~service_id
      ~instance_name
      ~port
  ;;
end
