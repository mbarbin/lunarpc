(*********************************************************************************)
(*  lunarpc - An opinionated, lightweight, HTTP/JSON RPC harness                 *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                                 *)
(*********************************************************************************)

type t =
  { app_name : App_name.t
  ; service_name : Service_name.t
  }

let compare t1 t2 =
  if phys_equal t1 t2
  then Ordering.Eq
  else (
    let { app_name = app_name1; service_name = service_name1 } = t1 in
    let { app_name = app_name2; service_name = service_name2 } = t2 in
    match App_name.compare app_name1 app_name2 with
    | (Lt | Gt) as ordering -> ordering
    | Eq -> Service_name.compare service_name1 service_name2)
;;

let equal t1 ({ app_name; service_name } as t2) =
  phys_equal t1 t2
  || (App_name.equal t1.app_name app_name
      && Service_name.equal t1.service_name service_name)
;;

let create ~app_name ~service_name = { app_name; service_name }

let to_dyn { app_name; service_name } =
  Dyn.Record
    [ "app_name", App_name.to_dyn app_name
    ; "service_name", Service_name.to_dyn service_name
    ]
;;
