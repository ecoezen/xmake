import("parse", {rootdir = path.join(os.scriptdir(), "..", "..", "..", "..", "..", "xmake", "modules", "private", "action", "require", "impl", "cps"), alias = "cps"})

local function _normpath(value)
    return value and value:gsub("\\", "/") or value
end

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

    local exported_file = path.join(scriptdir, "fixtures", "exported-layout.cps")
    local exported_mapped, exported_diags = cps(exported_file, {prefix = "C:/pkg/mylib"})
    t:require(exported_mapped)
    t:are_equal(_normpath(exported_mapped.components.mylib.includes[1]), "C:/pkg/mylib/include")
    t:are_equal(_normpath(exported_mapped.components.mylib.location), "C:/pkg/mylib/lib/mylib.lib")
    t:are_equal(#exported_diags, 0)

    local cmake_file = path.join(scriptdir, "fixtures", "cmake-consume-smoke.cps")
    local cmake_mapped = cps(cmake_file)
    t:require(cmake_mapped)
    t:are_equal(cmake_mapped.package.name, "cmake-smoke")
    t:are_equal(cmake_mapped.components.core.location, "lib/cmake-smoke.a")

    local reloc_file = path.join(scriptdir, "fixtures", "windows-relocation.cps")
    local reloc_mapped = cps(reloc_file, {prefix = "D:/relocated/winreloc"})
    t:require(reloc_mapped)
    t:are_equal(_normpath(reloc_mapped.components.winreloc.location), "D:/relocated/winreloc/lib/winreloc.lib")

    local mixed_file = path.join(scriptdir, "fixtures", "mixed-cps-noncps.cps")
    local mixed_mapped, mixed_diags = cps(mixed_file, {known_requires = { ["cpsdep::core"] = true }})
    t:require(mixed_mapped)
    t:require(#mixed_diags > 0)
    t:are_equal(mixed_diags[1].code, "unknown-require-fallback")
end
