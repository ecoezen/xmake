{
  "name": "hybridapp",
  "cps_version": "0.13.0",
  "version": "1.0.0",
  "requires": {
    "zlib": {
      "components": ["zlib"],
      "hints": "C:/deps/zlib"
    }
  },
  "components": {
    "hybridapp": {
      "type": "archive",
      "requires": ["zlib::zlib"],
      "location": "lib/hybridapp.lib"
    }
  }
}
