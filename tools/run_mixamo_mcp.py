"""Launch HaD0Yun's standalone server using the active Python environment.

Install the pinned upstream source and mcp==1.30.0 in a private venv first.
See docs/MIXAMO_MCP_SETUP.zh-TW.md. No credentials belong in this file.
"""
import builtins
import functools
import os
import sys

os.umask(0o077)

from mixamo_mcp import client

# Upstream debug prints otherwise corrupt the JSON-RPC stdout stream.
client.print = functools.partial(builtins.print, file=sys.stderr)

from mixamo_mcp import server

# Secret injection avoids sending credentials through recorded MCP arguments.
# The constructor uses this value in memory; unlike the setter it does not save it.
if os.environ.get("MIXAMO_ACCESS_TOKEN"):
    server.client = client.MixamoClient(access_token=os.environ["MIXAMO_ACCESS_TOKEN"])

if __name__ == "__main__":
    server.main()
