module IOVec = Dream_httpaf.IOVec

type t =
  { connection : Dream_httpaf.Client_connection.t
  ; body       : Dream_httpaf.Body.Writer.t }

(* TODO(anmonteiro): yet another argument, `~config` *)
let create
    ~nonce
    ~headers
    ~error_handler
    ~response_handler
    target
  =
  let connection = Dream_httpaf.Client_connection.create ?config:None in
  let body =
    Dream_httpaf.Client_connection.request
      connection
      (Handshake.create_request ~nonce ~headers target)
      ~error_handler
      ~response_handler
  in
  { connection
  ; body
  }
;;

let next_read_operation t =
  Dream_httpaf.Client_connection.next_read_operation t.connection

let next_write_operation t =
  Dream_httpaf.Client_connection.next_write_operation t.connection

let read t =
  Dream_httpaf.Client_connection.read t.connection

let yield_reader t =
  Dream_httpaf.Client_connection.yield_reader t.connection

let report_write_result t =
  Dream_httpaf.Client_connection.report_write_result t.connection

let yield_writer t =
  Dream_httpaf.Client_connection.yield_writer t.connection

let report_exn t exn =
  Dream_httpaf.Client_connection.report_exn t.connection exn

let is_closed t =
  Dream_httpaf.Client_connection.is_closed t.connection

let close t =
  Dream_httpaf.Body.Writer.close t.body;
  Dream_httpaf.Client_connection.shutdown t.connection
