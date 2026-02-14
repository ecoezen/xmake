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
    raise("TODO(cps L1): parser and mapping assertions are pending implementation")
end
