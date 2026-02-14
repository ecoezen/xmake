{
  "cps_version": "0.13.0",
  "name": "libbar",
  "description": "A shared library depending on libfoo.",
  "cps_path": "@prefix@/lib/cps/libbar",
  "license": "Apache-2.0",
  "version": "2.1.0",
  "requires": {
    "libfoo": {
      "version": "1.0.0"
    }
  },
  "default_components": [
    "libbar"
  ],
  "components": {
    "libbar": {
      "type": "dylib",
      "location": "@prefix@/lib/libbar.so",
      "includes": [
        "@prefix@/include"
      ],
      "requires": [
        "libfoo:libfoo"
      ],
      "link_flags": [],
      "compile_flags": [],
      "definitions": {
        "*": {}
      },
      "link_libraries": [],
      "link_location": null,
      "link_languages": [
        "cpp"
      ]
    }
  }
}
