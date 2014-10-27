local addonName, addonPrivate = ...
local addonNamespace = {}
_G[addonName] = addonNamespace
setmetatable(addonNamespace, {__index = _G})
setmetatable(addonPrivate, {__index = _G})
