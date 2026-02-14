import("parse", {rootdir = path.join(os.scriptdir(), "..", "..", "..", "..", "xmake", "modules", "private", "action", "require", "impl", "cps"), alias = "cps"})

local function _assert_fixtures(scriptdir)
    local fixtures = {
        "direct-requires.cps",
        "stage-fallback.cps",
        "mixed-partial-graph.cps",
        "malformed-transitive.cps"
    }
    local fixturesdir = path.join(scriptdir, "fixtures")
    for _, filename in ipairs(fixtures) do
        assert(os.isfile(path.join(fixturesdir, filename)), "missing cps resolver fixture: " .. filename)
    end
end

function main(t)
    local scriptdir = path.directory(t.filename)
    _assert_fixtures(scriptdir)

    local direct_file = path.join(scriptdir, "fixtures", "direct-requires.cps")
    local direct_mapped, direct_diags = cps(direct_file)
    t:require(direct_mapped)
    t:are_equal(direct_mapped.components.app.requires, {"zlib::zlib"})
    t:are_equal(#direct_diags, 0)

    local staged_file = path.join(scriptdir, "fixtures", "stage-fallback.cps")
    local staged_mapped, staged_diags = cps(staged_file, {stage_requires_fallback = true})
    t:require(staged_mapped)
    t:are_equal(staged_mapped.components.net.compile_requires, {"openssl::crypto"})
    t:are_equal(staged_mapped.components.net.link_requires, {"openssl::ssl"})
    t:are_equal(staged_mapped.components.net.dyld_requires, {"openssl::ssl"})
    t:are_equal(staged_mapped.components.net.requires, {"openssl::crypto", "openssl::ssl"})
    t:require(#staged_diags > 0)
    t:are_equal(staged_diags[1].code, "degraded-stage-requires")

    local mixed_file = path.join(scriptdir, "fixtures", "mixed-partial-graph.cps")
    local mixed_mapped, mixed_diags = cps(mixed_file, {known_requires = { ["known::core"] = true }})
    t:require(mixed_mapped)
    t:require(#mixed_diags > 0)
    t:are_equal(mixed_diags[1].code, "unknown-require-fallback")

    local malformed_file = path.join(scriptdir, "fixtures", "malformed-transitive.cps")
    local malformed_result, malformed_diags, malformed_errors = cps(malformed_file)
    t:are_equal(malformed_result, nil)
    t:require(malformed_errors)
    t:are_equal(malformed_diags[1].code, "invalid-requires")
end
