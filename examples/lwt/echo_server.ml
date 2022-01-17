let connection_handler : Unix.sockaddr -> Lwt_unix.file_descr -> unit Lwt.t =
  let module Body = Dream_httpaf.Body in
  let module Headers = Dream_httpaf.Headers in
  let module Reqd = Dream_httpaf.Reqd in
  let module Response = Dream_httpaf.Response in
  let module Status = Dream_httpaf.Status in

  let websocket_handler _client_address wsd =
    let frame ~opcode ~is_fin:_ ~len:_ payload =
      match (opcode: Websocketaf.Websocket.Opcode.t) with
      | #Websocketaf.Websocket.Opcode.standard_non_control as opcode ->
        Websocketaf.Payload.schedule_read payload
          ~on_eof:ignore
          ~on_read:(fun bs ~off ~len ->
          Websocketaf.Wsd.schedule wsd bs ~kind:opcode ~off ~len)
      | `Connection_close ->
        Websocketaf.Wsd.close wsd
      | `Ping ->
        Websocketaf.Wsd.send_pong wsd
      | `Pong
      | `Other _ ->
        ()
    in
    let eof () =
      Format.eprintf "EOF\n%!";
      Websocketaf.Wsd.close wsd
    in
    { Websocketaf.Server_connection.frame
    ; eof
    }
  in

  let error_handler _client_address wsd (`Exn exn) =
    let message = Printexc.to_string exn in
    let payload = Bytes.of_string message in
    Websocketaf.Wsd.send_bytes wsd ~kind:`Text payload ~off:0
      ~len:(Bytes.length payload);
    Websocketaf.Wsd.close wsd
  in

  Websocketaf_lwt_unix.Server.create_connection_handler
    ?config:None
    ~websocket_handler
    ~error_handler



let () =
  let open Lwt.Infix in

  let port = ref 8080 in
  Arg.parse
    ["-p", Arg.Set_int port, " Listening port number (8080 by default)"]
    ignore
    "Echoes websocket messages. Runs forever.";

  let listen_address = Unix.(ADDR_INET (inet_addr_loopback, !port)) in

  Lwt.async begin fun () ->
    Lwt_io.establish_server_with_client_socket
      listen_address connection_handler
    >>= fun _server ->
      Printf.printf "Listening on port %i and echoing websocket messages.\n" !port;
      flush stdout;
      Lwt.return_unit
  end;

  let forever, _ = Lwt.wait () in
  Lwt_main.run forever
