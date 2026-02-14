{
  "name": "mylib",
  "cps_version": "0.13.0",
  "version": "1.0.0",
  "configurations": ["release"],
  "components": {
    "core": {
      "type": "archive",
      "includes": ["include"],
      "location": "lib/core.lib",
      "configurations": {
        "release": {
          "includes": ["include/release"],
          "location": "lib/release/core.lib"
        },
        "debug": {
          "includes": ["include/debug"],
          "location": "lib/debug/core.lib"
        }
      }
    }
  }
}
