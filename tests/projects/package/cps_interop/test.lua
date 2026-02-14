local function _assert_fixtures(scriptdir)
    local fixtures =
        {"exported-layout.cps", "cmake-consume-smoke.cps", "windows-relocation.cps", "mixed-cps-noncps.cps"}
    local fixturesdir = path.join(scriptdir, "fixtures")
    for _, filename in ipairs(fixtures) do
        assert(os.isfile(path.join(fixturesdir, filename)), "missing cps interop fixture: " .. filename)
    end
end

function main(t)
    local scriptdir = path.directory(t.filename)
    _assert_fixtures(scriptdir)
    raise("TODO(cps L4): export/consume interop assertions are pending implementation")
end
