import("parse", {rootdir = path.join(os.scriptdir(), "..", "..", "..", "xmake", "modules", "private", "action", "require", "impl", "cps"), alias = "cps"})
import("package", {rootdir = path.join(os.scriptdir(), "..", "..", "..", "xmake", "modules", "private", "action", "require", "impl"), alias = "package_impl"})

local function _assert_fixtures(scriptdir)
    local fixtures = {
        "valid-single.cps",
        "valid-components.cps",
        "malformed-missing-name.cps",
        "unsupported-field.cps",
        "config-selection.cps",
        "version-semantics.cps",
        "version-unsupported-schema.cps",
        "version-missing.cps",
        "package-requires.cps",
        "package-requires-invalid.cps"
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

function test_cps_require_load_seam(t)
    local scriptdir = path.directory(t.filename)
    local cpsfile = path.join(scriptdir, "fixtures", "valid-single.cps")
    local requires = {cpsfile}
    local requires_extra = {}
    requires_extra[cpsfile] = {format = "cps", prefix = "C:/deps/zlib"}
    local requireitems = package_impl.load_requires(requires, requires_extra, {})
    t:are_equal(#requireitems, 1)
    t:are_equal(requireitems[1].name, "zlib")
    t:are_equal(requireitems[1].info.format, "cps")
    t:require(requireitems[1].info.cpsinfo)
    t:are_equal(requireitems[1].info.cpsinfo.components.zlib.location, path.join("C:/deps/zlib", "lib", "zlib.lib"))

    local autodetect_requires = {cpsfile}
    local autodetect_items = package_impl.load_requires(autodetect_requires, {}, {})
    t:are_equal(#autodetect_items, 1)
    t:are_equal(autodetect_items[1].name, "zlib")
    t:are_equal(autodetect_items[1].info.format, "cps")
    t:require(autodetect_items[1].info.cpsinfo)

    local explicit_file = path.join(scriptdir, "fixtures", "component-explicit.cps")
    local explicit_requires = {explicit_file}
    local explicit_extra = {}
    explicit_extra[explicit_file] = {format = "cps", components = {"crypto"}}
    local explicit_items = package_impl.load_requires(explicit_requires, explicit_extra, {})
    t:are_equal(#explicit_items, 1)
    t:are_equal(explicit_items[1].name, "openssl")
    t:are_equal(explicit_items[1].info.cpsinfo.package.selected_components, {"crypto"})
end

function test_cps_component_selection(t)
    local scriptdir = path.directory(t.filename)

    local by_default_file = path.join(scriptdir, "fixtures", "component-default.cps")
    local mapped_default = cps(by_default_file)
    t:require(mapped_default)
    t:are_equal(mapped_default.package.selected_components, {"ssl"})
    t:require(mapped_default.components.ssl)
    t:are_equal(mapped_default.components.crypto, nil)

    local explicit_file = path.join(scriptdir, "fixtures", "component-explicit.cps")
    local mapped_explicit = cps(explicit_file, {components = {"crypto"}})
    t:require(mapped_explicit)
    t:are_equal(mapped_explicit.package.selected_components, {"crypto"})
    t:require(mapped_explicit.components.crypto)
    t:are_equal(mapped_explicit.components.ssl, nil)

    local single_file = path.join(scriptdir, "fixtures", "valid-single.cps")
    local mapped_single = cps(single_file)
    t:require(mapped_single)
    t:are_equal(mapped_single.package.selected_components, {"zlib"})

    local ambiguous_file = path.join(scriptdir, "fixtures", "component-ambiguous.cps")
    local ambiguous_result, ambiguous_diags, ambiguous_errors = cps(ambiguous_file)
    t:are_equal(ambiguous_result, nil)
    t:require(ambiguous_errors)
    t:are_equal(ambiguous_diags[1].code, "component-selection-required")
end

function test_cps_configuration_selection(t)
    local scriptdir = path.directory(t.filename)
    local config_file = path.join(scriptdir, "fixtures", "config-selection.cps")

    local mapped_user = cps(config_file, {components = {"core"}, configurations = {"debug", "release"}})
    t:require(mapped_user)
    t:are_equal(mapped_user.package.selected_configuration, "debug")
    t:are_equal(mapped_user.components.core.location, "lib/debug/core.lib")
    t:are_equal(mapped_user.components.core.includes, {"include/debug"})

    local mapped_package = cps(config_file, {components = {"core"}})
    t:require(mapped_package)
    t:are_equal(mapped_package.package.selected_configuration, "release")
    t:are_equal(mapped_package.components.core.location, "lib/release/core.lib")

    local mapped_base = cps(config_file, {components = {"core"}, configurations = {"profile"}})
    t:require(mapped_base)
    t:are_equal(mapped_base.package.selected_configuration, "release")
    t:are_equal(mapped_base.components.core.location, "lib/release/core.lib")

    local explicit_file = path.join(scriptdir, "fixtures", "component-explicit.cps")
    local explicit_requires = {explicit_file}
    local explicit_extra = {}
    explicit_extra[explicit_file] = {format = "cps", components = {"crypto"}}
    local explicit_items = package_impl.load_requires(explicit_requires, explicit_extra, {})
    t:are_equal(#explicit_items, 1)
    t:are_equal(explicit_items[1].name, "openssl")
    t:are_equal(explicit_items[1].info.cpsinfo.package.selected_components, {"crypto"})

    local seam_requires = {config_file}
    local seam_extra = {}
    seam_extra[config_file] = {format = "cps", components = {"core"}, cps_configurations = {"debug"}}
    local seam_items = package_impl.load_requires(seam_requires, seam_extra, {})
    t:are_equal(#seam_items, 1)
    t:are_equal(seam_items[1].info.cpsinfo.package.selected_configuration, "debug")
end

function test_cps_version_semantics(t)
    local scriptdir = path.directory(t.filename)

    local version_file = path.join(scriptdir, "fixtures", "version-semantics.cps")
    local version_mapped, version_diags = cps(version_file)
    t:require(version_mapped)
    t:are_equal(version_mapped.package.version, "2.4.1")
    t:are_equal(version_mapped.package.compat_version, "2.1.0")
    t:are_equal(version_mapped.package.version_schema, "simple")
    t:are_equal(version_mapped.package.version_exact_only, false)
    t:are_equal(#version_diags, 0)

    local unsupported_file = path.join(scriptdir, "fixtures", "version-unsupported-schema.cps")
    local unsupported_mapped, unsupported_diags = cps(unsupported_file)
    t:require(unsupported_mapped)
    t:are_equal(unsupported_mapped.package.version_schema, "pep440")
    t:are_equal(unsupported_mapped.package.version_exact_only, true)
    t:require(#unsupported_diags > 0)
    t:are_equal(unsupported_diags[1].code, "unsupported-version-schema-exact-only")

    local missing_file = path.join(scriptdir, "fixtures", "version-missing.cps")
    local missing_mapped, missing_diags = cps(missing_file)
    t:require(missing_mapped)
    t:are_equal(missing_mapped.package.version, nil)
    t:are_equal(missing_mapped.package.compat_version, nil)
    t:are_equal(missing_mapped.package.version_exact_only, true)
    t:require(#missing_diags > 0)
    t:are_equal(missing_diags[1].code, "missing-version-exact-only")
end

function test_cps_package_requires_mapping(t)
    local scriptdir = path.directory(t.filename)

    local requires_file = path.join(scriptdir, "fixtures", "package-requires.cps")
    local requires_mapped, requires_diags = cps(requires_file)
    t:require(requires_mapped)
    t:require(requires_mapped.package.requires)
    t:are_equal(requires_mapped.package.requires.zlib.components, {"zlib"})
    t:are_equal(requires_mapped.package.requires.zlib.hints, {"C:/deps/zlib", "D:/cache/zlib"})
    t:are_equal(requires_mapped.package.requires.openssl.components, {})
    t:are_equal(requires_mapped.package.requires.openssl.hints, {})
    t:are_equal(#requires_diags, 0)

    local invalid_file = path.join(scriptdir, "fixtures", "package-requires-invalid.cps")
    local invalid_mapped, invalid_diags, invalid_errors = cps(invalid_file)
    t:are_equal(invalid_mapped, nil)
    t:require(invalid_errors)
    t:are_equal(invalid_diags[1].code, "invalid-package-requirement-hints")
end
