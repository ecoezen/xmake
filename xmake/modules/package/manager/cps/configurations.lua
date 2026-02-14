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
-- @file        configurations.lua
--

function main()
    return
    {
        cps_filepath = {description = "Use an explicit CPS file path, e.g. path/to/foo.cps"},
        cpsdirs = {description = "Set CPS search directories, e.g. {\"/usr/local/share/cps\"}"},
        prefixdirs = {description = "Set CPS prefix roots, e.g. {\"/usr/local\"}"},
        cps_prefix = {description = "Override CPS prefix relocation root"},
        cps_components = {description = "Select CPS components, e.g. {\"core\"}"},
        cps_configurations = {description = "Set preferred CPS configurations, e.g. {\"Release\"}"}
    }
end
