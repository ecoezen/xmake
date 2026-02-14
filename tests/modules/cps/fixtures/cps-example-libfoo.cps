{
    "cps_version": "0.13.0",
    "name": "libfoo",
    "description": "A minimal static C library.",
    "cps_path": "@prefix@/lib/cps/libfoo",
    "license": "MIT",
    "version": "1.0.0",
    "default_components": [
        "libfoo"
    ],
    "components": {
        "libfoo": {
            "type": "archive",
            "location": "@prefix@/lib/libfoo.a",
            "includes": [
                "@prefix@/include"
            ],
            "requires": [],
            "link_flags": [],
            "compile_flags": [],
            "definitions": {
                "*": {}
            },
            "link_libraries": [],
            "link_location": null,
            "link_languages": [
                "c"
            ]
        }
    }
}
