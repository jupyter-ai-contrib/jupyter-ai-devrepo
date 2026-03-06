# jupyter_server_config.py
# MCP server configuration for the devrepo.

c.MCPExtensionApp.mcp_port = 18741
c.MCPExtensionApp.mcp_name = "Jupyter MCP Server"

c.MCPExtensionApp.mcp_tools = [
    "jupyter_ai_tools.toolkits.notebook:add_cell",
]
