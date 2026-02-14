{
  "name": "netlib",
  "version": "1.0.0",
  "components": {
    "net": {
      "type": "archive",
      "compile_requires": ["openssl::crypto"],
      "link_requires": ["openssl::ssl"],
      "dyld_requires": ["openssl::ssl"],
      "location": "lib/net.a"
    }
  }
}
