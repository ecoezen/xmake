{
  "name": "hybridapp",
  "cps_version": "0.13.0",
  "version": "1.0.0",
  "requires": {
    "zlib": {
      "components": ["zlib"],
      "hints": ["C:/deps/zlib", "D:/cache/zlib"]
    },
    "openssl": null
  },
  "components": {
    "hybridapp": {
      "type": "archive",
      "requires": ["zlib::zlib", "openssl::ssl"],
      "location": "lib/hybridapp.lib"
    }
  }
}
