local addonName, addonPrivate = ...
setfenv(1, addonPrivate)

local locales = {}

local defaultLocale

local function NewLocale(name, metatable)
	local locale = {name=name, proxy={}, data={}}
	setmetatable(locale.proxy, {
		__index = function(proxy, key)
			return metatable.index(locale, key)
		end,
		__newindex = function(proxy, key, value)
			return metatable.newindex(locale, key, value)
		end
	})
	locales[name] = locale
end

local DefaultLocaleMetatable = {}

function DefaultLocaleMetatable.index(locale, key)
	return locale.data[key] or error(key.." is undefined in default locale "..locale.name)
end

function DefaultLocaleMetatable.newindex(locale, key, value)
	if locale.data[key] then
		error(key.." already defined in "..locale.name.." as "..locale.data[key])
	end
	locale.data[key] = value
end

local LocaleMetatable = {}

function LocaleMetatable.index(locale, key)
	return locale.data[key] or defaultLocale.data[key] or error(key.." undefined in either "..locale.name.. " or default locale "..defaultLocale.name)
end

function LocaleMetatable.newindex(locale, key, value)
	if locale.data[key] then
		error(key.." already defined in "..locale.name.." as "..locale.data[key])
	end
	if not defaultLocale.data[key] then
		error(key.." being defined in "..locale.name.." but not defined in default locale "..defaultLocale.name)
	end
	locale.data[key] = value
end

Locales = {}

local defaultSet = false

function Locales.Get(localeName)
	localeName = localeName or GetLocale()
	if not defaultSet then 
		NewLocale(localeName, DefaultLocaleMetatable)
		defaultLocale = locales[localeName]
		defaultSet = true
	elseif not locales[localeName] then
		NewLocale(localeName, LocaleMetatable)
	end
	return locales[localeName].proxy
end

function Locales.L(localeName)
	local locale = Locales.Get(localeName)
	return function(key)
		return locale[key]
	end
end
