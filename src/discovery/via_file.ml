(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module Unix = UnixLabels

let ( / ) a s = Absolute_path.extend a (Fsegment.v s)

let default_root ~root_directory =
  match root_directory with
  | Some root -> root
  | None ->
    (match Sys.getenv_opt "HOME" with
     | None -> Unix.getcwd ()
     | Some home -> home)
    |> Absolute_path.v
;;

let discovery_directory ~root_directory ~service_id:{ Service_id.app_name; service_name } =
  root_directory
  / ("." ^ App_name.to_string app_name)
  / "service-discovery"
  / Service_name.to_string service_name
;;

let file_suffix = ".discovery"

let discovery_path ~root_directory ~service_id ~instance_name =
  discovery_directory ~root_directory ~service_id
  / (Instance_name.to_string instance_name ^ file_suffix)
;;

let rec mkdirs (path : Absolute_path.t) =
  let invalid_file_kind () =
    Err.raise
      ~loc:(Loc.of_file ~path:(path :> Fpath.t))
      [ Pp.text "Invalid file kind for directory."
      ; Dyn.pp (Dyn.Record [ "path", Dyn.string (Absolute_path.to_string path) ])
      ]
  in
  match (Unix.stat (Absolute_path.to_string path)).st_kind with
  | exception Unix.Unix_error (ENOENT, _, _) ->
    (match Absolute_path.parent path with
     | None -> () [@coverage off]
     | Some path -> mkdirs path);
    Unix.mkdir (Absolute_path.to_string path) ~perm:0o755
  | exception Unix.Unix_error (ENOTDIR, _, _) ->
    (* [Absolute_path.to_string] renders directory-style paths with a
       trailing slash, so [Unix.stat] on a path whose last existing
       component is a non-directory raises [ENOTDIR] here rather than
       succeeding with a non-[S_DIR] kind below. *)
    invalid_file_kind ()
  | S_DIR -> ()
  | S_REG | S_CHR | S_BLK | S_LNK | S_FIFO | S_SOCK -> invalid_file_kind ()
;;

let advertize_server ~root_directory ~service_id ~instance_name ~port =
  let discovery_path = discovery_path ~root_directory ~service_id ~instance_name in
  Option.iter (Absolute_path.parent discovery_path) ~f:(fun parent_dir ->
    mkdirs parent_dir);
  Discovery_file.save { port } ~path:(discovery_path :> Fpath.t);
  at_exit (fun () ->
    try Unix.unlink (Absolute_path.to_string discovery_path) with
    | _ -> ())
;;

let discovery_files ~root_directory ~service_id =
  let discovery_directory = discovery_directory ~root_directory ~service_id in
  let directory = Absolute_path.to_string discovery_directory in
  if not (Sys.file_exists directory && Sys.is_directory directory)
  then []
  else
    Sys.readdir directory
    |> Array.filter ~f:(fun entry -> String.ends_with entry ~suffix:file_suffix)
    |> Array.sorted_copy ~compare:String.compare
    |> Array.map ~f:(fun entry -> discovery_directory / entry)
    |> Array.to_list
;;

let find_server ~root_directory ~service_id () =
  match discovery_files ~root_directory ~service_id with
  | discovery_file :: _ -> Discovery_file.load ~path:(discovery_file :> Fpath.t)
  | [] ->
    Err.raise
      [ Pp.text "Service_discovery: no server found."
      ; Dyn.pp (Dyn.Record [ "service_id", Service_id.to_dyn service_id ])
      ]
;;
