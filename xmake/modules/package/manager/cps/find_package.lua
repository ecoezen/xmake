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
-- @file        find_package.lua
--

-- imports
import("core.project.target")
import("private.action.require.impl.cps.parse", {alias = "cps_parse"})

local function _append_unique(values, value)
    if value and value ~= "" and not table.contains(values, value) then
        table.insert(values, value)
    end
end

local function _append_unique_path(values, value)
    if not value or value == "" then
        return
    end
    if not path.is_absolute(value) then
        value = path.absolute(value)
    end
    _append_unique(values, value)
end

local function _collect_searchdirs(opt)
    local searchdirs = {}
    local configs = opt.configs or {}

    for _, cpsdir in ipairs(table.wrap(configs.cpsdirs)) do
        _append_unique_path(searchdirs, cpsdir)
    end

    local prefixdirs = table.join(table.wrap(configs.prefixdirs), table.wrap(opt.prefixdirs))
    local cmake_prefix_path = os.getenv("CMAKE_PREFIX_PATH")
    if cmake_prefix_path then
        table.join2(prefixdirs, path.splitenv(cmake_prefix_path))
    end
    for _, prefix in ipairs(prefixdirs) do
        if prefix and prefix ~= "" then
            if not path.is_absolute(prefix) then
                prefix = path.absolute(prefix)
            end
            _append_unique(searchdirs, prefix)
            _append_unique(searchdirs, path.join(prefix, "cps"))
            _append_unique(searchdirs, path.join(prefix, "share", "cps"))
            _append_unique(searchdirs, path.join(prefix, "lib", "cps"))
            _append_unique(searchdirs, path.join(prefix, "lib64", "cps"))
        end
    end
    return searchdirs
end

local function _infer_prefix(cpsfile, cpsdir)
    if cpsdir and cpsdir ~= "" then
        if cpsdir:endswith(path.join("share", "cps")) then
            return path.directory(path.directory(cpsdir))
        elseif cpsdir:endswith(path.join("lib", "cps")) then
            return path.directory(path.directory(cpsdir))
        elseif cpsdir:endswith(path.join("lib64", "cps")) then
            return path.directory(path.directory(cpsdir))
        elseif cpsdir:endswith("cps") then
            return path.directory(cpsdir)
        end
    end
    return path.directory(cpsfile)
end

local function _find_cpsfile(name, opt)
    local configs = opt.configs or {}
    local cpsfile = configs.cps_filepath
    if cpsfile then
        if not path.is_absolute(cpsfile) then
            cpsfile = path.absolute(cpsfile)
        end
        if os.isfile(cpsfile) then
            return cpsfile, path.directory(cpsfile)
        end
        return
    end

    local basenames = {name .. ".cps", name:lower() .. ".cps"}
    for _, cpsdir in ipairs(_collect_searchdirs(opt)) do
        if os.isdir(cpsdir) then
            for _, basename in ipairs(basenames) do
                local filepath = path.join(cpsdir, basename)
                if os.isfile(filepath) then
                    return filepath, cpsdir
                end
            end
        end
    end
end

local function _map_component(result, component, opt)
    if component.includes then
        result.includedirs = result.includedirs or {}
        for _, includedir in ipairs(component.includes) do
            _append_unique(result.includedirs, includedir)
        end
    end

    local location = component.location
    if location and type(location) == "string" and location ~= "" then
        result.libfiles = result.libfiles or {}
        result.linkdirs = result.linkdirs or {}
        result.links = result.links or {}
        _append_unique(result.libfiles, location)
        _append_unique(result.linkdirs, path.directory(location))
        local linkname = target.linkname(path.filename(location), {plat = opt.plat})
        if linkname then
            _append_unique(result.links, linkname)
        end
        if location:endswith(".a") or location:endswith(".lib") then
            result.static = true
        elseif location:endswith(".so") or location:find(".so.", 1, true) or location:endswith(".dylib") or location:endswith(".dll") then
            result.shared = true
        end
    end
end

local function _map_result(cpsinfo, opt)
    local result = {}
    local packageinfo = cpsinfo.package or {}
    result.version = packageinfo.version

    local selected_components = packageinfo.selected_components or {}
    for _, component_name in ipairs(selected_components) do
        local component = cpsinfo.components and cpsinfo.components[component_name]
        if component then
            _map_component(result, component, opt)
        end
    end

    if result.links or result.includedirs then
        return result
    end
end

function main(name, opt)
    opt = opt or {}
    local cpsfile, cpsdir = _find_cpsfile(name, opt)
    if not cpsfile then
        return
    end

    local configs = opt.configs or {}
    local cps_prefix = configs.cps_prefix
    if not cps_prefix then
        cps_prefix = _infer_prefix(cpsfile, cpsdir)
    end
    local cpsinfo = cps_parse(cpsfile, {
        prefix = cps_prefix,
        stage_requires_fallback = true,
        components = configs.cps_components or configs.components,
        configurations = configs.cps_configurations
    })
    if not cpsinfo then
        return
    end
    return _map_result(cpsinfo, opt)
end
