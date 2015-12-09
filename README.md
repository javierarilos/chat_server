# chat_server
chat server written in Erlang.

## How to run
* Run Erlang (from the dir containing this file): erl
* Compile the module.
* Run the server on a given port.

```erlang
c(chat_server).
chat_server:start_chat_server(9990).
```

* Connect with 1 or more clients.

```bash
nc localhost 9990
```
