import("cps", {rootdir = path.join(os.scriptdir(), "..", "..", "..", "..", "xmake", "modules", "private", "action", "require", "impl"), alias = "cps"})

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

    local install_file = path.join(scriptdir, "fixtures", "install-with-cps.cps")
    local install_mapped, install_diags = cps(install_file, {known_requires = { ["zlib::zlib"] = true }})
    t:require(install_mapped)
    t:are_equal(install_mapped.package.name, "libpng")
    t:are_equal(install_mapped.components.png.requires, {"zlib::zlib"})
    t:are_equal(#install_diags, 0)

    local fetch_file = path.join(scriptdir, "fixtures", "fetch-with-fallback.cps")
    local fetch_mapped, fetch_diags = cps(fetch_file, {known_requires = { ["zlib::zlib"] = true }})
    t:require(fetch_mapped)
    t:require(#fetch_diags > 0)
    t:are_equal(fetch_diags[1].code, "unknown-require-fallback")

    local absent_file = path.join(scriptdir, "fixtures", "absent-cps-fallback.cps")
    local absent_mapped, absent_diags = cps(absent_file)
    t:require(absent_mapped)
    t:require(#absent_diags > 0)
    t:are_equal(absent_diags[1].code, "empty-components-fallback")
end
