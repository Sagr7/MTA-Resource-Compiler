--------------------------------------------------------------------
-----------------Auto Resource Compiler by Overlord-----------------
--------------------------------------------------------------------
local Compiler = {}

outputChatBox("Compiler by Overlord started", root)
outputChatBox("type /compile [resource name] [type (0,1,2)]", root)

local thisResource = getThisResource()

function Compiler.compile(player, cmd, rName, cType)
	if not rName then 
		outputChatBox("ERROR : /compile [resource name] [type (0,1,2)]", player)
		return
	end

	cType = cType or 2
	
	local res = getResourceFromName(rName)
	if not res then return outputChatBox("Couldn't find that resource.", player) end
	
	local resMeta = XML.load(":"..rName.."/meta.xml")
	
	local newPath = "compiled/"..getTickCount().."_"..rName.."/"
	local newMeta = XML(newPath.."meta.xml", "meta")
	local logFile = newPath.."compiler_log.txt"
	
	local total = #resMeta.children
	local current = 0
	
	Compiler.log(logFile, "OVERLORD's COMPILER -- COMPILATION REQUESTED")
	Compiler.log(logFile, "NAME: "..rName.."; SCRIPTS: "..(#resMeta:findChilds("script") or 0).."; FILES: "..(#resMeta:findChilds("file") or 0).."; OTHERS: "..(#resMeta.children - (#resMeta:findChilds("file") + #resMeta:findChilds("script"))).."; TOTAL: "..#resMeta.children.."; OBFUSCATE: "..cType)
	
	local fExistance = 
		thisResource:getOrganizationalPath().."/"
		..thisResource.name.."/"..newPath
		
	outputDebugString("Compilation for resource "..rName.." requested by "..getPlayerName(player))
	outputDebugString("The output should exist in "..fExistance)
	
	for i, node in ipairs(resMeta.children) do
		
		local nodeName = node.name
		if nodeName == "info" then
			local child = newMeta:createChild("info")
			local toLog = ""
			
			for attr, val in pairs(node.attributes) do
				child:setAttribute(attr, val)
				toLog = toLog..attr.." = "..val.."; "
			end
			
			current = current + 1
			outputChatBox("Processed: [#00ff00"..current.." / "..total.."#ffffff] -#0000ff Info", player, 255, 255, 255, true)
			Compiler.log(logFile, "["..current.." / "..total.."] ".."INFO: Added "..toLog)
			
		elseif nodeName == "file" then
			local child = newMeta:createChild("file")
			for attr, val in pairs(node.attributes) do
				child:setAttribute(attr, val)
				
				if attr == "src" then
					Timer(function()
						fileCopy(":"..rName.."/"..val, newPath..val)
						current = current + 1
						outputChatBox("Processed: [#00ff00"..current.." / "..total.."#ffffff]  -#0000ff File", player, 255, 255, 255, true)						
						Compiler.log(logFile, "["..current.." / "..total.."] ".."File: COPIED FROM "..res:getOrganizationalPath().."/"..rName.."/"..val.." TO "..fExistance..val)
					end, i*200, 1)
				end
			end

		elseif nodeName == "script" then
			local child = newMeta:createChild("script")
			
			for attr, val in pairs(node.attributes) do				
				if attr == "src" then
					child:setAttribute(attr, val:gsub(".lua", ".luac"))					
					Timer(
						function()
							fetchRemote( "http://luac.mtasa.com/?compile=1&debug=0&obfuscate="..cType, function(data)
								local sSize = Compiler.save(newPath..val:gsub(".lua", ".luac"),data)
								current = current + 1
								outputChatBox("Processed: [#00ff00"..current.." / "..total.."#ffffff] -#0000ff Script", player, 255, 255, 255, true)
								
								Compiler.log(logFile, "["..current.." / "..total.."] ".."SCRIPT: COMPILED "..res:getOrganizationalPath().."/"..rName.."/"..val.." ("..tostring(Compiler.load(":"..rName.."/"..val)):len().." byte) TO "..fExistance..val:gsub(".lua", ".luac").." ("..sSize.." byte)")
							end, Compiler.load(":"..rName.."/"..val), true)
							
						end, i*300, 1
					)
					
				else
					child:setAttribute(attr, val)
				end
			end
			
		else
			local child = newMeta:createChild(nodeName)
			for attr, val in pairs(node.attributes) do
				if attr == "src" then
					local _ = fileCopy(":"..rName.."/"..val, newPath..val) and nil or nil
				end
				child:setAttribute(attr, val)
			end
			child.value = node.value
			
			current = current + 1
			outputChatBox("Processed: [#00ff00"..current.." / "..total.."#ffffff] -#0000ff Others", player, 255, 255, 255, true)
			Compiler.log(logFile, "["..current.." / "..total.."] ".."OTHERS: "..nodeName)
		end
	end
	
	newMeta:saveFile()
	newMeta:unload()
end
addCommandHandler("compile", Compiler.compile)

function XML:findChilds(fName)	-- a function that returns all childs under a specific name
	local f = {}
	for _, node in ipairs(self.children) do
		if node.name == fName then f[#f+1] = node end
	end
	return f
end

function Compiler.load(dir)
	local file = File(dir)
	return file:read(file.size), file:close()
end

function Compiler.save(name, data)
	local file = File(name)
	return file:write(data), file:close()
end

function Compiler.log(file, data)
	file = File(file)
	local time = getRealTime()
	time = string.format("%04d-%02d-%02d %02d:%02d:%02d", time.year+1900, time.month + 1, time.monthday, time.hour, time.minute, time.second)
	file.pos = file.size
	file:write("\r\n----------------------------\r\n"
		..time.." : "..data
	)
	file:close()
end

--[[	--a short one, cancelled (works just fine)
Compiler.load, Compiler.save = 
	function(dir)
		local file = File(dir)
		return file:read(file.size), file:close()
	end, 
	function(name, data)
		local file = File(name)
		return file:write(data), file:close()
	end	
--]]

--Overriding to print in console when requested from there
_outputChatBox = outputChatBox
function outputChatBox(...)
	local args = {...}	
	if isElement(args[2]) and args[2].type == "console" then
		outputDebugString(args[1]:raw())
	end
	_outputChatBox(...)
end

function string:raw()
	return self:gsub("#%x%x%x%x%x%x", "")
end

