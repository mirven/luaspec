package = "LuaSpec"
version = "0.5-1"
source = {
	url = "http://marcusirven.s3.amazonaws.com/rocks/luaspec-"..version..".zip"
}
description = {
	summary = "A context specification framework",
	detailed = [[
		A context specification framework.
	]],
	homepage = "http://github.com/mirven/luaspec", 
	license = "MIT/X11" -- same a Lua
}
dependencies = {
	"lua >= 5.1"
}
build = {
	type = "builtin";
	modules = {
		luaspec = 'src/luaspec.lua';
		luamock = 'src/luamock.lua';
	}
}
