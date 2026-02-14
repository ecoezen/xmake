{
  "name": "openssl",
  "cps_version": "0.13.0",
  "version": "3.2.1",
  "default_components": ["ssl"],
  "components": {
    "ssl": {
      "type": "archive",
      "requires": ["crypto"],
      "includes": ["include"]
    },
    "crypto": {
      "type": "archive",
      "includes": ["include"]
    }
  }
}
