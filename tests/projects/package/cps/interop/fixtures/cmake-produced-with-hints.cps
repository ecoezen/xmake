{
  "cps_version": "0.13",
  "name": "cmake-upstream",
  "version": "1.2.0",
  "requires": {
    "zlib": {
      "components": ["zlib"],
      "hints": ["C:/vendor/zlib", "D:/cache/zlib"]
    }
  },
  "components": {
    "core": {
      "type": "archive",
      "requires": ["zlib::zlib"],
      "location": "lib/cmake-upstream.a"
    }
  }
}
