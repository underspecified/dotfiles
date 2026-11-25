"""Verify TLS through the OS trust store in an MCP server (dotfiles#36).

On PYTHONPATH for the servers that ../bootstrap.sh starts with
`uvx --with truststore`. Does nothing where truststore is not installed, such
as a child Python that inherits PYTHONPATH.
"""

try:
    import truststore
except ImportError:
    pass
else:
    # Where truststore is not installed, pyright takes this directory for it.
    truststore.inject_into_ssl()  # pyright: ignore[reportAttributeAccessIssue]
