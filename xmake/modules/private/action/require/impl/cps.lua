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
-- @author      ruki
-- @file        cps.lua
--

-- imports
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
    if type(cpsdata.components) ~= "table" then
        local err = "missing required field: components"
        table.insert(diagnostics, _new_diag("error", "missing-components", err, "components"))
        return nil, diagnostics, err
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
            version = cpsdata.version,
            prefix = prefix
        },
        components = {}
    }

    for component_name, component in pairs(cpsdata.components) do
        if type(component) == "table" then
            local requires = _to_string_array(component.requires)
            if requires == nil then
                local err = string.format("component '%s' has invalid requires (expect array of strings)", component_name)
                table.insert(diagnostics, _new_diag("error", "invalid-requires", err, "components." .. component_name .. ".requires"))
                return nil, diagnostics, err
            end
            local includes = _to_string_array(component.includes)
            if includes == nil then
                local err = string.format("component '%s' has invalid includes (expect array of strings)", component_name)
                table.insert(diagnostics, _new_diag("error", "invalid-includes", err, "components." .. component_name .. ".includes"))
                return nil, diagnostics, err
            end
            for i, value in ipairs(includes) do
                includes[i] = _resolve_prefix(value, prefix)
            end
            mapped.components[component_name] = {
                type = component.type,
                requires = requires,
                includes = includes,
                location = _resolve_prefix(component.location, prefix)
            }
        end
    end
    return mapped, diagnostics
end
