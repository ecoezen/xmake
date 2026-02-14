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
    raise("TODO(cps L2): resolver and transitive fallback assertions are pending implementation")
end
