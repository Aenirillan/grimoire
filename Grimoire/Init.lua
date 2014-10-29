local addonName, addonPrivate = ...

Grimoire = {}
Grimoire.addonName = addonName

setmetatable(Grimoire, {__index = _G})
setmetatable(addonPrivate, {__index = _G})

