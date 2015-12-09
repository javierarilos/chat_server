-module(chat_server).
-export([start_chat_server/1, connection_handler/0]).

%% Simple chat server, Erlang's hello world.

apply_for_all(_, []) ->
  true;
apply_for_all(Fun, [Pid | T]) ->
  Fun(Pid),
  apply_for_all(Fun, T).

start_connection_handler() ->
  case whereis(connectionhandler) of
    undefined -> true;
    _         -> unregister(connectionhandler)
  end,
  ConnHdlrPid = spawn(chat_server, connection_handler, []),
  register(connectionhandler, ConnHdlrPid).

add_pid(Pid) ->
  case get(client_pids) of
    undefined -> put(client_pids, [Pid]);
    List      -> put(client_pids, [Pid | List])
  end.

connection_handler() ->
  receive
    {newclient, Pid} ->
      io:format("Received newclient ~p connectionhandler is: ~p ~n", [Pid, self()]),
      add_pid(Pid);
    {message, Bin} ->
      io:format("connection_handler (~p ) broadcast message to get(client_pids) : ~p ~n", [self(), get(client_pids)]),
      apply_for_all(fun(Pid) -> Pid ! {message, Bin} end, get(client_pids))
  end,
  connection_handler().

start_chat_server(Port) ->
  start_connection_handler(),
  {ok, Listen} = gen_tcp:listen(Port, [binary, {packet, 0}]),
  spawn(fun() -> wait_for_connection(Listen) end).

start_client_process(Listen) ->
  spawn(fun() -> wait_for_connection(Listen) end).

wait_for_connection(Listen) ->
  io:format("~p waiting for connections ...~n", [self()]),
  {ok, Socket} = gen_tcp:accept(Listen),
  start_client_process(Listen),
  connectionhandler ! {newclient, self()},
  client_identification(Socket).

client_identification(Socket) ->
  gen_tcp:send(Socket, "Input your name : "),
  receive
    {tcp, Socket, Bin} ->
      List = binary_to_list(Bin),
      Username = string:substr(List,1, string:len(List) - 1),
      io:format("new user ~p~n", [Username]),
      gen_tcp:send(Socket, "Welcome: " ++ Username ++ "\n"),
      client_message(Socket, Username);
    {tcp_closed, Socket} -> io:format("Server socket closed ~n");
    Event -> io:format("Received and event ~p~n", [Event])
  end.

client_message(Socket, Username) ->
  receive
    {tcp, Socket, Bin} ->
      io:format("client sent a message. pid(~p) => ~p in ~n", [self(), Bin]),
      NamedBin = Username ++ " > " ++ Bin,
      connectionhandler ! {message, NamedBin},
      client_message(Socket, Username);
    {tcp_closed, Socket} -> io:format("Server socket closed ~n");
    {message, Bin} ->
      io:format("pid(~p) Received a message event ~p ~n", [self(), Bin]),
      gen_tcp:send(Socket, Bin),
      client_message(Socket, Username)
  end.
