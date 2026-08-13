(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

module Key = struct
  include Keyval.Key

  let generator =
    let open Generator in
    map
      (string_non_empty_of (union [ char_alphanum; return '_' ]))
      ~f:(fun s ->
        match of_string s with
        | Ok t -> t
        | Error (`Msg _) -> assert false)
  ;;
end

module Value = struct
  include Keyval.Value

  let generator = Generator.map Generator.string_non_empty ~f:of_string
end

module Owner = struct
  include Keyval.Owner

  let generator =
    let open Generator in
    map
      (string_non_empty_of (union [ char_alphanum; return '-'; return '_' ]))
      ~f:(fun s ->
        match of_string s with
        | Ok t -> t
        | Error (`Msg _) -> assert false)
  ;;
end
