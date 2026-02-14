{
    "cps_version": "0.13.0",
    "name": "libexample",
    "description": "A general-purpose static library example.",
    "cps_path": "@prefix@/lib/cps/libexample",
    "license": "MIT",
    "version": "1.0.0",
    "requires": {
        "libfoo": {
            "version": "1.0.0"
        },
        "libbar": {
            "version": "2.1.0"
        }
    },
    "default_components": [
        "libexample"
    ],
    "components": {
        "libexample": {
            "type": "archive",
            "location": "@prefix@/lib/libexample.a",
            "includes": [
                "@prefix@/include"
            ],
            "requires": ["libfoo:libfoo", "libbar:libbar"],
            "link_flags": [],
            "compile_flags": [],
            "definitions": {
                "*": {}
            },
            "link_libraries": [],
            "link_location": null,
            "link_languages": [
                "cpp", "c"
            ]
        }
    }
}
