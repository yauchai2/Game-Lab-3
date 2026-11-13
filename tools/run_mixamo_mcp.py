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

from mixamo_mcp.server import main

if __name__ == "__main__":
    main()
