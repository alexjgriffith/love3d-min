-- bootstrap the compiler
fennel = require("fennel")

local make_love_searcher = function(env,predicate)
   return function(module_name)
      local path = predicate .. module_name:gsub("%.", "/") .. ".fnl"
      if love.filesystem.getInfo(path) then
         return function(...)
            local code = love.filesystem.read(path)
            return fennel.eval(code, {env=env}, ...)
         end, path
      end
   end
end

table.insert(package.loaders, make_love_searcher(_G, ""))

math.randomseed( os.time() )

require("perspective")
