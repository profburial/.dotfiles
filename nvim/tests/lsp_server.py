#!/usr/bin/env python3
"""Deterministic external language server for editor behavior checks."""
import json
import pathlib
import sys
import time

mode = sys.argv[1]
root = pathlib.Path(sys.argv[2])


def send(message: dict[str, object]) -> None:
    data = json.dumps(message).encode()
    sys.stdout.buffer.write(f"Content-Length: {len(data)}\r\n\r\n".encode() + data)
    sys.stdout.buffer.flush()


while True:
    headers = {}
    while True:
        line = sys.stdin.buffer.readline()
        if not line:
            sys.exit(0)
        if line in (b"\r\n", b"\n"):
            break
        key, value = line.decode().split(":", 1)
        headers[key.lower()] = value.strip()
    request = json.loads(sys.stdin.buffer.read(int(headers["content-length"])))
    method = request.get("method")
    if method == "exit":
        break
    if "id" not in request:
        continue
    result = None
    error = None
    if method == "initialize":
        result = {"capabilities": {"textDocumentSync": 1, "completionProvider": {"triggerCharacters": ["."]}, "definitionProvider": True, "renameProvider": True, "hoverProvider": True, "documentFormattingProvider": mode.startswith("format_")}}
    elif method == "rubyLsp/workspace/dependencies":
        if mode == "error":
            error = {"code": -32603, "message": "fixture dependency failure"}
        elif mode == "malformed":
            result = [{"name": "broken"}]
        elif mode == "missing":
            result = None
        else:
            if mode == "delayed":
                time.sleep(0.2)
            result = [
                {"name": "direct", "version": "1.2.3", "dependency": True, "path": str(root / "direct.rb")},
                {"name": "transitive", "version": "4.5.6", "dependency": False, "path": str(root / "transitive.rb")},
            ]
    elif method == "textDocument/completion":
        result = {"isIncomplete": False, "items": [{"label": "tvim_call", "kind": 3, "insertTextFormat": 2, "insertText": "tvim_call(${1:value})$0"}]}
    elif method == "textDocument/formatting":
        result = [{"range": {"start": {"line": 0, "character": 0}, "end": {"line": 0, "character": 3}}, "newText": mode.removeprefix("format_")}]
    elif method == "textDocument/definition":
        result = {"uri": (root / "destination.lua").as_uri(), "range": {"start": {"line": 1, "character": 0}, "end": {"line": 1, "character": 5}}}
    elif method == "textDocument/rename":
        result = {"changes": {request["params"]["textDocument"]["uri"]: [{"range": {"start": {"line": 0, "character": 0}, "end": {"line": 0, "character": 3}}, "newText": request["params"]["newName"]}]}}
    reply = {"jsonrpc": "2.0", "id": request["id"]}
    reply.update({"error": error} if error else {"result": result})
    send(reply)
