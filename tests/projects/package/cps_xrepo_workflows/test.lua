local function _assert_fixtures(scriptdir)
    local fixtures = {
        "install-with-cps.cps",
        "fetch-with-fallback.cps",
        "absent-cps-fallback.cps"
    }
    local fixturesdir = path.join(scriptdir, "fixtures")
    for _, filename in ipairs(fixtures) do
        assert(os.isfile(path.join(fixturesdir, filename)), "missing cps xrepo fixture: " .. filename)
    end
end

function main(t)
    local scriptdir = path.directory(t.filename)
    _assert_fixtures(scriptdir)
    raise("TODO(cps L3): xrepo install/fetch compatibility assertions are pending implementation")
end
