# MCP Server Workflow

Before using any IBM i command:

1. Verify MCP Server is running.

Check:

http://localhost:3000

Expected response:

{"success":true,"message":"MCP Server Running"}


Step0 MCP Server確認

MCP確認には以下を使用する。

Invoke-RestMethod -Uri "http://localhost:3000"

curl は使用しない。

MCP Serverが起動済みと明示されている場合は
Step0を省略してよい。

If MCP Server is not running:

1. Open folder:
   C:\Users\K4293\mcp-server

2. Execute task:
   Start MCP Server

3. Verify localhost:3000

Do not execute IBM i commands until MCP Server is running.