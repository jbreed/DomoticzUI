

local light = {}
local light_mt = { __index = light }	-- metatable

local padding = 5
local blockWidth = _W/7-padding
local json = require('json')

-------------------------------------------------
-- Private FUNCTIONS
-------------------------------------------------

function light.new( info )	-- constructor
		
	local newLight = {
		Name = info.Name,
		State = info.Status,
		Type = info.Type,
		id = info.idx,
		Block = {null},
	}
	
	return setmetatable( newLight, light_mt )
end

-------------------------------------------------

local function buttonPushed(event)
	if event.isError then
		print("Error sending command")
	else
		print(event.response)
		return true
	end
end

local function turnOn(id, sourceType)
	print("On - "..id..sourceType)
	if sourceType == 'Group' then
		if(network.request( beginUrl.."/json.htm?type=command&param=switchscene&idx="..id.."&switchcmd=On", "GET", buttonPushed )) then
			return true
		else
			return false
		end
	elseif sourceType == 'Lighting 2' then

	end
end

local function turnOff(id, sourceType)
	print("Off - "..id..sourceType)
	if sourceType == 'Group' then
		if(network.request( beginUrl.."/json.htm?type=command&param=switchscene&idx="..id.."&switchcmd=Off", "GET", buttonPushed )) then
			return true
		else
			return false
		end
	elseif sourceType == 'Lighting 2' then

	end
end

local function toggle(id, sourceType, name)
	if sourceType == 'Group' then
		local function onComplete( event )
		   if event.action == "clicked" then
		        local i = event.index
		        if i == 1 then
		            if(network.request( beginUrl.."/json.htm?type=command&param=switchscene&idx="..id.."&switchcmd=On", "GET", buttonPushed ) ) then
		            	return 'On'
	            	end
		        elseif i == 2 then
		            if(network.request( beginUrl.."/json.htm?type=command&param=switchscene&idx="..id.."&switchcmd=Off", "GET", buttonPushed ) ) then
		            	return 'Off'
	            	end
	            elseif i == 3 then
	            	return 'Cancel'
		        end
		    end
		end

		local alert = native.showAlert( name, "Select a function.", { "On", "Off", "Cancel" }, onComplete )
	elseif sourceType == 'Lighting 2' then

	end
	return true
end

local function changeColor(block, color)
	if color == 'green' then
		block:setFillColor(.3,.8,.5)
	elseif color == 'grey' then
		block:setFillColor( .6)
	elseif color == 'blue' then
		block:setFillColor( 50/255, 115/255, 213/255)
	end
end

-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------

function light:compareStates(currState)
	if self.State ~= currState then
		self.State = currState
		if self.State == "Off" then
			changeColor(self.Block, "grey")
		elseif self.State == "On" then
			changeColor(self.Block, "green")
		else
			changeColor(self.Block, "blue")
		end
	end
end

function light:createBlock(column, row)
	local blockGroup = display.newGroup()
	local newBlock

	local function onSelect(event)
		if event.phase == 'ended' then
			if self.State == 'Off' then
				if(turnOn(self.id, self.Type)) then
					self.State = 'On'
					changeColor(self.Block, "green")
				end
			elseif self.State == 'On' then
				if(turnOff(self.id, self.Type)) then
					changeColor(self.Block, "grey")
					self.State = 'Off'
				end
			else
				local result = toggle(self.id, self.Type, self.Name)
				if result == "On" then
					self.State = 'On'
					changeColor(self.Block, "green")
				elseif result == "Off" then
					changeColor(self.Block, "grey")
					self.State = 'Off'
				end
			end
		end
		return true
	end

	newBlock = display.newRoundedRect(blockGroup, column, row, blockWidth, blockWidth, 2 )
	newBlock.anchorX = 0
	newBlock.anchorY = 0
	newBlock:addEventListener("touch", onSelect)
	self.Block = newBlock

	if self.State == 'Off' then
		changeColor(self.Block, "grey")
	elseif self.State == 'Mixed' then
		changeColor(self.Block, "blue")
	else
		changeColor(self.Block, "green")
	end

	local blockTitle =  display.newText(blockGroup, string.sub(self.Name, 1, 12), newBlock.x+newBlock.width*.5, newBlock.y+newBlock.height*.2, native.systemFont, 12 )
	blockTitle:setFillColor( 1 )

	local light = display.newImageRect(blockGroup, "Images/lightbulb.png", 30, 30)
	light.x = newBlock.x+newBlock.width*.5
	light.y = newBlock.y+newBlock.height*.6

	return blockGroup
end

-------------------------------------------------

return light