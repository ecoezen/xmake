{
  "cps_version": "0.13",
  "name": "openssl",
  "version": "3.2.0",
  "components": {
    "crypto": {
      "type": "archive",
      "includes": ["include"],
      "location": "lib/libcrypto.a"
    },
    "ssl": {
      "type": "archive",
      "requires": ["crypto"],
      "includes": ["include"],
      "location": "lib/libssl.a"
    }
  }
}
