--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      Emin Can Özen (ecozen)
-- @file        parse.lua
--

import("core.base.json")

local function _new_diag(level, code, message, field)
    return {
        level = level,
        code = code,
        message = message,
        field = field
    }
end

local function _resolve_prefix(value, prefix)
    if type(value) ~= "string" then
        return value
    end
    if not prefix or prefix == "" then
        return value
    end
    value = value:gsub("@prefix@", prefix)
    value = value:gsub("%${prefix}", prefix)
    if not path.is_absolute(value) and not value:find("%${prefix}", 1, true) then
        value = path.join(prefix, value)
    end
    return value
end

local function _to_string_array(value)
    if value == nil then
        return {}
    end
    if type(value) ~= "table" then
        return nil
    end
    local result = {}
    for _, item in ipairs(value) do
        if type(item) ~= "string" then
            return nil
        end
        table.insert(result, item)
    end
    return result
end

local function _join_unique(dst, src)
    local exists = {}
    for _, item in ipairs(dst) do
        exists[item] = true
    end
    for _, item in ipairs(src) do
        if not exists[item] then
            table.insert(dst, item)
            exists[item] = true
        end
    end
end

local function _sorted_component_names(components)
    local names = {}
    for name, _ in pairs(components or {}) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

local function _normalize_component_name(packagename, component_name)
    if not component_name then
        return nil
    end
    if component_name:startswith(packagename .. "::") then
        return component_name:sub(#packagename + 3)
    end
    return component_name
end

local function _select_configuration(cpsdata, component, opt, diagnostics)
    local component_configurations = component and component.configurations
    if type(component_configurations) ~= "table" then
        return nil
    end
    local preference = {}
    local user_preference = _to_string_array(opt.configurations)
    if user_preference == nil then
        local err = "invalid selected configurations (expect array of strings)"
        table.insert(diagnostics, _new_diag("error", "invalid-selected-configurations", err, "configurations"))
        return nil, err
    end
    if user_preference then
        for _, name in ipairs(user_preference) do
            table.insert(preference, name)
        end
    end
    local package_preference = _to_string_array(cpsdata.configurations)
    if package_preference == nil then
        local err = "invalid package configurations (expect array of strings)"
        table.insert(diagnostics, _new_diag("error", "invalid-package-configurations", err, "configurations"))
        return nil, err
    end
    if package_preference then
        for _, name in ipairs(package_preference) do
            table.insert(preference, name)
        end
    end
    for _, name in ipairs(preference) do
        if type(component_configurations[name]) == "table" then
            return name
        end
    end
    return nil
end

local function _has_key(tbl, key)
    if type(tbl) ~= "table" then
        return false
    end
    for current_key, _ in pairs(tbl) do
        if current_key == key then
            return true
        end
    end
    return false
end

local function _get_component_attribute(component, configuration_name, attribute_name)
    local configuration = nil
    if configuration_name and type(component.configurations) == "table" then
        configuration = component.configurations[configuration_name]
    end
    if type(configuration) == "table" and _has_key(configuration, attribute_name) then
        local value = configuration[attribute_name]
        if value == json.null then
            return nil, true
        end
        return value, true
    end
    return component[attribute_name], false
end

local function _select_components(cpsdata, opt, diagnostics)
    local selected = {}
    local selected_set = {}
    local components = cpsdata.components or {}
    local component_names = _sorted_component_names(components)
    if #component_names == 0 then
        return {}
    end
    local explicit_components = _to_string_array(opt.components)
    if explicit_components == nil then
        local err = "invalid selected components (expect array of strings)"
        table.insert(diagnostics, _new_diag("error", "invalid-selected-components", err, "components"))
        return nil, err
    end

    if explicit_components and #explicit_components > 0 then
        for _, name in ipairs(explicit_components) do
            local normalized = _normalize_component_name(cpsdata.name, name)
            if type(components[normalized]) ~= "table" then
                local err = string.format("selected component '%s' not found", name)
                table.insert(diagnostics, _new_diag("error", "missing-selected-component", err, "components"))
                return nil, err
            end
            if not selected_set[normalized] then
                table.insert(selected, normalized)
                selected_set[normalized] = true
            end
        end
        return selected
    end

    local defaults = _to_string_array(cpsdata.default_components)
    if defaults == nil then
        local err = "invalid default_components (expect array of strings)"
        table.insert(diagnostics, _new_diag("error", "invalid-default-components", err, "default_components"))
        return nil, err
    end
    if defaults and #defaults > 0 then
        for _, name in ipairs(defaults) do
            if type(components[name]) ~= "table" then
                local err = string.format("default component '%s' not found", name)
                table.insert(diagnostics, _new_diag("error", "missing-default-component", err, "default_components"))
                return nil, err
            end
            if not selected_set[name] then
                table.insert(selected, name)
                selected_set[name] = true
            end
        end
        return selected
    end

    if #component_names == 1 then
        return {component_names[1]}
    end

    local err = "component selection required: provide explicit components or default_components"
    table.insert(diagnostics, _new_diag("error", "component-selection-required", err, "components"))
    return nil, err
end

local function _map_version_info(cpsdata, diagnostics)
    local version = cpsdata.version
    if version ~= nil and type(version) ~= "string" then
        local err = "invalid version (expect string)"
        table.insert(diagnostics, _new_diag("error", "invalid-version", err, "version"))
        return nil, err
    end
    local compat_version = cpsdata.compat_version
    if compat_version ~= nil and type(compat_version) ~= "string" then
        local err = "invalid compat_version (expect string)"
        table.insert(diagnostics, _new_diag("error", "invalid-compat-version", err, "compat_version"))
        return nil, err
    end
    if compat_version == nil then
        compat_version = version
    end
    local version_schema = cpsdata.version_schema or "simple"
    if type(version_schema) ~= "string" or version_schema == "" then
        local err = "invalid version_schema (expect non-empty string)"
        table.insert(diagnostics, _new_diag("error", "invalid-version-schema", err, "version_schema"))
        return nil, err
    end

    local version_exact_only = false
    if not version then
        version_exact_only = true
        local warn = "package version is missing; exact version matching only"
        table.insert(diagnostics, _new_diag("warning", "missing-version-exact-only", warn, "version"))
    end
    if version_schema == "custom" then
        version_exact_only = true
        local warn = "version_schema=custom is treated as exact-only in MVP"
        table.insert(diagnostics, _new_diag("warning", "custom-version-schema-exact-only", warn, "version_schema"))
    elseif version_schema ~= "simple" then
        version_exact_only = true
        local warn = string.format("version_schema '%s' is unsupported in MVP and treated as exact-only", version_schema)
        table.insert(diagnostics, _new_diag("warning", "unsupported-version-schema-exact-only", warn, "version_schema"))
    end

    return {
        version = version,
        compat_version = compat_version,
        version_schema = version_schema,
        version_exact_only = version_exact_only
    }
end

local function _map_package_requires(cpsdata, diagnostics)
    if cpsdata.requires == nil then
        return {}
    end
    if type(cpsdata.requires) ~= "table" then
        local err = "invalid package requires (expect map(requirement))"
        table.insert(diagnostics, _new_diag("error", "invalid-package-requires", err, "requires"))
        return nil, err
    end

    local mapped_requires = {}
    for package_name, requirement in pairs(cpsdata.requires) do
        if type(package_name) ~= "string" or package_name == "" then
            local err = "invalid package requires key (expect non-empty package name)"
            table.insert(diagnostics, _new_diag("error", "invalid-package-require-name", err, "requires"))
            return nil, err
        end
        if requirement == json.null or requirement == nil then
            requirement = {}
        end
        if type(requirement) ~= "table" then
            local err = string.format("invalid requirement object for package '%s'", package_name)
            table.insert(diagnostics, _new_diag("error", "invalid-package-requirement", err, "requires." .. package_name))
            return nil, err
        end

        local components = _to_string_array(requirement.components)
        if components == nil then
            local err = string.format("invalid requirement components for package '%s' (expect array of strings)", package_name)
            table.insert(diagnostics, _new_diag("error", "invalid-package-requirement-components", err, "requires." .. package_name .. ".components"))
            return nil, err
        end
        local hints = _to_string_array(requirement.hints)
        if hints == nil then
            local err = string.format("invalid requirement hints for package '%s' (expect array of strings)", package_name)
            table.insert(diagnostics, _new_diag("error", "invalid-package-requirement-hints", err, "requires." .. package_name .. ".hints"))
            return nil, err
        end

        mapped_requires[package_name] = {
            components = components,
            hints = hints
        }
    end
    return mapped_requires
end

function main(filepath, opt)
    opt = opt or {}
    local diagnostics = {}
    local cpsdata, errors = json.loadfile(filepath)
    if not cpsdata then
        return nil, diagnostics, errors
    end
    if type(cpsdata) ~= "table" then
        local err = "invalid cps document: root must be an object"
        table.insert(diagnostics, _new_diag("error", "invalid-root", err, "$"))
        return nil, diagnostics, err
    end
    if type(cpsdata.name) ~= "string" or cpsdata.name == "" then
        local err = "missing required field: name"
        table.insert(diagnostics, _new_diag("error", "missing-name", err, "name"))
        return nil, diagnostics, err
    end
    if type(cpsdata.cps_version) ~= "string" or cpsdata.cps_version == "" then
        local err = "missing required field: cps_version"
        table.insert(diagnostics, _new_diag("error", "missing-cps-version", err, "cps_version"))
        return nil, diagnostics, err
    end
    if type(cpsdata.components) ~= "table" then
        local err = "missing required field: components"
        table.insert(diagnostics, _new_diag("error", "missing-components", err, "components"))
        return nil, diagnostics, err
    end
    local has_components = false
    for _, _ in pairs(cpsdata.components) do
        has_components = true
        break
    end
    if not has_components then
        table.insert(diagnostics, _new_diag("warning", "empty-components-fallback", "components is empty, fallback to non-cps flows", "components"))
    end
    if cpsdata.extensions ~= nil then
        table.insert(diagnostics, _new_diag("warning", "unsupported-field", "extensions is not mapped in L1", "extensions"))
    end

    local prefix = opt.prefix or cpsdata.prefix
    if prefix == "${prefix}" then
        prefix = opt.prefix
    end

    local mapped = {
        package = {
            name = cpsdata.name,
            prefix = prefix
        },
        components = {}
    }

    local version_info, version_error = _map_version_info(cpsdata, diagnostics)
    if not version_info then
        return nil, diagnostics, version_error
    end
    mapped.package.version = version_info.version
    mapped.package.compat_version = version_info.compat_version
    mapped.package.version_schema = version_info.version_schema
    mapped.package.version_exact_only = version_info.version_exact_only

    local package_requires, package_requires_error = _map_package_requires(cpsdata, diagnostics)
    if not package_requires then
        return nil, diagnostics, package_requires_error
    end
    mapped.package.requires = package_requires

    local selected_components, selection_error = _select_components(cpsdata, opt, diagnostics)
    if not selected_components then
        return nil, diagnostics, selection_error
    end
    mapped.package.selected_components = selected_components
    local selected_component_set = {}
    for _, name in ipairs(selected_components) do
        selected_component_set[name] = true
    end
    local selected_configuration = nil

    for component_name, component in pairs(cpsdata.components) do
        if selected_component_set[component_name] and type(component) == "table" then
            local configuration_name, configuration_error = _select_configuration(cpsdata, component, opt, diagnostics)
            if configuration_error then
                return nil, diagnostics, configuration_error
            end
            if configuration_name and not selected_configuration then
                selected_configuration = configuration_name
            end

            local requires_value, requires_explicit = _get_component_attribute(component, configuration_name, "requires")
            local requires = _to_string_array(requires_value)
            if requires == nil then
                local err = string.format("component '%s' has invalid requires (expect array of strings)", component_name)
                table.insert(diagnostics, _new_diag("error", "invalid-requires", err, "components." .. component_name .. ".requires"))
                return nil, diagnostics, err
            end
            if not requires and requires_explicit then
                requires = {}
            end
            local compile_requires_value, compile_requires_explicit = _get_component_attribute(component, configuration_name, "compile_requires")
            local compile_requires = _to_string_array(compile_requires_value)
            if compile_requires == nil then
                local err = string.format("component '%s' has invalid compile_requires (expect array of strings)", component_name)
                table.insert(diagnostics, _new_diag("error", "invalid-compile-requires", err, "components." .. component_name .. ".compile_requires"))
                return nil, diagnostics, err
            end
            if not compile_requires and compile_requires_explicit then
                compile_requires = {}
            end
            local link_requires_value, link_requires_explicit = _get_component_attribute(component, configuration_name, "link_requires")
            local link_requires = _to_string_array(link_requires_value)
            if link_requires == nil then
                local err = string.format("component '%s' has invalid link_requires (expect array of strings)", component_name)
                table.insert(diagnostics, _new_diag("error", "invalid-link-requires", err, "components." .. component_name .. ".link_requires"))
                return nil, diagnostics, err
            end
            if not link_requires and link_requires_explicit then
                link_requires = {}
            end
            local dyld_requires_value, dyld_requires_explicit = _get_component_attribute(component, configuration_name, "dyld_requires")
            local dyld_requires = _to_string_array(dyld_requires_value)
            if dyld_requires == nil then
                local err = string.format("component '%s' has invalid dyld_requires (expect array of strings)", component_name)
                table.insert(diagnostics, _new_diag("error", "invalid-dyld-requires", err, "components." .. component_name .. ".dyld_requires"))
                return nil, diagnostics, err
            end
            if not dyld_requires and dyld_requires_explicit then
                dyld_requires = {}
            end
            local includes_value, includes_explicit = _get_component_attribute(component, configuration_name, "includes")
            local includes = _to_string_array(includes_value)
            if includes == nil then
                local err = string.format("component '%s' has invalid includes (expect array of strings)", component_name)
                table.insert(diagnostics, _new_diag("error", "invalid-includes", err, "components." .. component_name .. ".includes"))
                return nil, diagnostics, err
            end
            if not includes and includes_explicit then
                includes = {}
            end
            if opt.stage_requires_fallback then
                local staged_count = #compile_requires + #link_requires + #dyld_requires
                if staged_count > 0 then
                    _join_unique(requires, compile_requires)
                    _join_unique(requires, link_requires)
                    _join_unique(requires, dyld_requires)
                    local warn = string.format("component '%s' stage-specific requires are degraded into requires", component_name)
                    table.insert(diagnostics, _new_diag("warning", "degraded-stage-requires", warn, "components." .. component_name))
                end
            end
            if opt.known_requires and #requires > 0 then
                for _, require_name in ipairs(requires) do
                    if require_name:find("::", 1, true) and not opt.known_requires[require_name] then
                        local warn = string.format("component '%s' unresolved require '%s' uses fallback", component_name, require_name)
                        table.insert(diagnostics, _new_diag("warning", "unknown-require-fallback", warn, "components." .. component_name .. ".requires"))
                    end
                end
            end
            for i, value in ipairs(includes) do
                includes[i] = _resolve_prefix(value, prefix)
            end
            local location = _get_component_attribute(component, configuration_name, "location")
            mapped.components[component_name] = {
                type = component.type,
                requires = requires,
                compile_requires = compile_requires,
                link_requires = link_requires,
                dyld_requires = dyld_requires,
                includes = includes,
                location = _resolve_prefix(location, prefix)
            }
        end
    end
    mapped.package.selected_configuration = selected_configuration
    return mapped, diagnostics
end
