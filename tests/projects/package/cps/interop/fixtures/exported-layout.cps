{
  "cps_version": "0.13",
  "name": "mylib",
  "version": "1.0.0",
  "prefix": "${prefix}",
  "components": {
    "mylib": {
      "type": "archive",
      "includes": ["${prefix}/include"],
      "location": "${prefix}/lib/mylib.lib"
    }
  }
}
