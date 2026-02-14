import("parse", {rootdir = path.join(os.scriptdir(), "..", "..", "..", "xmake", "modules", "private", "action", "require", "impl", "cps"), alias = "cps"})

local function _assert_fixtures(scriptdir)
    local fixtures = {
        "valid-single.cps",
        "valid-components.cps",
        "malformed-missing-name.cps",
        "unsupported-field.cps"
    }
    local fixturesdir = path.join(scriptdir, "fixtures")
    for _, filename in ipairs(fixtures) do
        assert(os.isfile(path.join(fixturesdir, filename)), "missing cps fixture: " .. filename)
    end
end

function test_cps_parser_mapping_skeleton(t)
    local scriptdir = path.directory(t.filename)
    _assert_fixtures(scriptdir)

    local single_file = path.join(scriptdir, "fixtures", "valid-single.cps")
    local mapped_single, diags_single = cps(single_file, {prefix = "C:/deps/zlib"})
    t:require(mapped_single)
    t:are_equal(mapped_single.package.name, "zlib")
    t:are_equal(mapped_single.package.version, "1.3.1")
    t:are_equal(mapped_single.components.zlib.type, "archive")
    t:are_equal(mapped_single.components.zlib.includes, {path.join("C:/deps/zlib", "include")})
    t:are_equal(mapped_single.components.zlib.location, path.join("C:/deps/zlib", "lib", "zlib.lib"))
    t:are_equal(#diags_single, 0)

    local components_file = path.join(scriptdir, "fixtures", "valid-components.cps")
    local mapped_components, diags_components = cps(components_file)
    t:require(mapped_components)
    t:are_equal(mapped_components.package.name, "openssl")
    t:are_equal(mapped_components.components.ssl.requires, {"crypto"})
    t:are_equal(#diags_components, 0)

    local malformed_file = path.join(scriptdir, "fixtures", "malformed-missing-name.cps")
    local malformed_result, malformed_diags, malformed_errors = cps(malformed_file)
    t:are_equal(malformed_result, nil)
    t:require(malformed_errors)
    t:are_equal(malformed_diags[1].code, "missing-name")

    local unsupported_file = path.join(scriptdir, "fixtures", "unsupported-field.cps")
    local unsupported_result, unsupported_diags = cps(unsupported_file)
    t:require(unsupported_result)
    t:require(#unsupported_diags > 0)
    t:are_equal(unsupported_diags[1].code, "unsupported-field")
end
