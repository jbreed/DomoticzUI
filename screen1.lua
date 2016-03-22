-----------------------------------------------------------------------------------------
--
-- screen1.lua
-- Developer: Justin Breed; All Rights Reserved.
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )
local widget = require('widget')
local scene = composer.newScene()
local json = require('json')
local mime = require('mime')
local light = require('light')
local crypto = require( "crypto" )


local dateBlockDate
local dateBlockTime
local modeBlockText
local currentTemp
local todayHighLow
local todayPop
local tomHighLow
local tomPop
local dailyIcon
local tomIcon

local thermostatText
local thermoSetAt

local currentMode = 0
local popupEngaged = false
local sleepActive = false
local sleepBlock

local popupGroup

function scene:create( event )
	local sceneGroup = self.view

	local padding = 5
	local blockWidth = _W/7-padding
	local timeStamp = os.date("*t")

	local switchArray = {}

	local columnStart = padding*2+blockWidth*3
	local currentColumn = 1

	-- Function for dynamic blocks for switches/groups
	local function blockCreator(number, info)
		if number > 12 then
			return true
		end

		local row = padding

		if(number/3 > 1 and number/3 <= 2) then
			number = number - 3
			row = row + padding + blockWidth
		elseif(number/3 > 2 and number/3 <= 3) then
			number = number - 6
			row = row + padding*2 + blockWidth*2
		elseif(number/3 > 3 and number/3 <=4) then
			number = number - 9
			row = row + padding*3 + blockWidth*3
		end

		local column = columnStart+(number*(padding+blockWidth))

		local thisLight = light.new(info)

		local thisBlock = thisLight:createBlock(column, row)
		sceneGroup:insert(thisBlock)
		table.insert(switchArray, thisLight)
	end

	-- Create default blocks
	local bg = display.newRect( 0, 0, display.contentWidth, display.contentHeight )
	bg.anchorX = 0
	bg.anchorY = 0
	bg:setFillColor( .1 )
	sceneGroup:insert( bg )
	
	--===== DATE =====--

	local dateBlock = display.newRoundedRect( padding, padding, blockWidth*2+padding, blockWidth, 2 )
	dateBlock.anchorX = 0
	dateBlock.anchorY = 0
	dateBlock:setFillColor(.7,.3,.3)
	sceneGroup:insert( dateBlock )

	dateBlockDate =  display.newText( timeStamp.day.."/"..timeStamp.month.."/"..timeStamp.year, dateBlock.x+dateBlock.width*.5, dateBlock.y+dateBlock.height*.2, native.systemFont, 14 )
	dateBlockDate:setFillColor( 1 )

	dateBlockTime =  display.newText( os.date("%I")..":"..string.format( "%02d", timeStamp.min ) .. " " ..os.date("%p"), dateBlock.x+dateBlock.width*.5, dateBlock.y+dateBlock.height*.6, native.systemFontBold, 30 )
	dateBlockTime:setFillColor( 1 )

	--===== END DATE =====--
	--===== FORECAST =====--

	local forecastBlock = display.newRoundedRect( blockWidth*2+padding*3, padding, blockWidth*2-padding, blockWidth*2+padding, 2 )
	forecastBlock.anchorX = 0
	forecastBlock.anchorY = 0
	forecastBlock:setFillColor(.4,.2,.4)
	sceneGroup:insert( forecastBlock )

	local forecastBlockTitle = display.newText(sceneGroup, "Today", forecastBlock.x+forecastBlock.width*.5, forecastBlock.y+forecastBlock.height*.1, native.systemFont, 14)
	forecastBlockTitle:setFillColor(1)

	dailyIcon = display.newImageRect(sceneGroup, "Images/weather/Sunny.png", 55, 55)
	dailyIcon.x = forecastBlock.x+forecastBlock.width*.2
	dailyIcon.y = forecastBlock.y+forecastBlock.height*.29
	dailyIcon.anchorY = .5

	currentTemp = display.newText(sceneGroup, "*°", forecastBlock.x+forecastBlock.width*.67, forecastBlock.y+forecastBlock.height*.28, native.systemFontBold, 30)

	todayHighLow = display.newText(sceneGroup, "*/*", forecastBlock.x+forecastBlock.width*.3, forecastBlock.y+forecastBlock.height*.5, native.systemFont, 14)
	local todayUmbrella = display.newImage("Images/umb.png", forecastBlock.x+forecastBlock.width*.6, forecastBlock.y+forecastBlock.height*.5)
	todayUmbrella:scale(.23,.23)
	todayPop = display.newText(sceneGroup, "0%", forecastBlock.x+forecastBlock.width*.8, forecastBlock.y+forecastBlock.height*.5, native.systemFont, 14)
	

	local forecastSeparator = display.newLine( forecastBlock.x+forecastBlock.width*.1, forecastBlock.y+forecastBlock.height*.65, forecastBlock.x+forecastBlock.width*.9, forecastBlock.y+forecastBlock.height*.65 )
	forecastSeparator:setStrokeColor( 1 )
	forecastSeparator.strokeWidth = 1.5

	tomIcon = display.newImageRect(sceneGroup, "Images/weather/Sunny.png", 35, 35)
	tomIcon.x = forecastBlock.x+forecastBlock.width*.15
	tomIcon.y = forecastBlock.y+forecastBlock.height*.89
	tomIcon.anchorY = .5

	tomHighLow = display.newText(sceneGroup, "*/*", forecastBlock.x+forecastBlock.width*.45, forecastBlock.y+forecastBlock.height*.88, native.systemFont, 14)
	local tomUmbrella = display.newImage("Images/umb.png", forecastBlock.x+forecastBlock.width*.71, forecastBlock.y+forecastBlock.height*.88)
	tomUmbrella:scale(.23,.23)
	tomPop = display.newText(sceneGroup, "0%", forecastBlock.x+forecastBlock.width*.9, forecastBlock.y+forecastBlock.height*.88, native.systemFont, 14)


	local forecastBlockTitleTom = display.newText(sceneGroup, "Tomorrow", forecastBlock.x+forecastBlock.width*.5, forecastSeparator.y+forecastBlock.height*.1, native.systemFont, 12)
	forecastBlockTitleTom:setFillColor(1)

	--===== END FORECAST =====--
	-- Measured temperature and thermostat blocks -- 

	local thermostatBlock = display.newRoundedRect(sceneGroup, padding, blockWidth+padding*2, blockWidth, blockWidth, 2)
	thermostatBlock.anchorX = 0
	thermostatBlock.anchorY = 0
	thermostatBlock:setFillColor(.2,.7,.9)

	local thermostatTitle = display.newText(sceneGroup, "Current", thermostatBlock.x+thermostatBlock.width*.5, thermostatBlock.y+thermostatBlock.height*.2, native.systemFont, 14)
	thermostatTitle:setFillColor(1)

	thermostatText = display.newText(sceneGroup, "*", thermostatBlock.x+thermostatBlock.width*.5, thermostatBlock.y+thermostatBlock.height*.62, native.systemFontBold, 30)
	thermostatText:setFillColor(1)

	local function controlTemp(event)
		if event.phase == 'ended' then
			local oldTemp = thermoSetAt
			local tempChangeGroup = display.newGroup()
			local blackBg = display.newRect(tempChangeGroup, _W*.5, _H*.5, _W, _H)
			blackBg:setFillColor(0,0,0,.8)
			blackBg:addEventListener('touch', function() return true end)

			local boxBg = display.newRoundedRect(tempChangeGroup, _W*.5, _H*.5, _W*.25, _W*.3, 6)

			local boxTitle = display.newText(tempChangeGroup, "Set Thermostat", boxBg.x, boxBg.y-boxBg.height*.45, native.systemFontBold, 17)
			boxTitle:setFillColor(0)


			
			local currentSet = display.newText(tempChangeGroup, thermoSetAt.."°", _W*.5, _H*.55, native.systemFontBold, 32)
			currentSet:setFillColor(.3,.3,1)

			local function handleSetTemp(event)
				if event.phase == 'ended' then
					if oldTemp ~= thermoSetAt and event.target.id == 'setTemp' then
						-- Popup native spinner icon
						native.setActivityIndicator(true)
						print("Submitting new temp: "..thermoSetAt)

						local function tempServerResponseHandler(event)
							if event.isError then
								print("Error")
							else
								local res = json.decode(event.response)
								if res.status == 'ERROR' then
									print("Issue sending new temperature to the controller")
									thermoSetAt = oldTemp
								elseif res.status == "OK" then
									print("New temp submitted successfully.")
									thermostatSetText.text = thermoSetAt.."°"
								end
								-- REMOVE SPINNER
								native.setActivityIndicator(false)
							end
						end

						-- Make a network GET request to the thermostat to change the setpoint to the new number
						network.request( beginUrl.."/json.htm?type=command&param=udevice&idx="..thermostatId.."&nvalue=0&svalue="..thermoSetAt, "GET", tempServerResponseHandler)
						
					else
						thermoSetAt = oldTemp
					end		
					local function removeListener()
						tempChangeGroup:removeSelf()
					end
					transition.to(tempChangeGroup, { time=500, alpha=0, onComplete=removeListener})
				end
				return true
			end

			local confirmBtn = widget.newButton
			{
			    x=boxBg.x+boxBg.width*.25,
			    y=boxBg.y+boxBg.y*.5-boxBg.height*.14,
			    fillColor = { default={ .4,.8,.4 }, over={ .3,.9,.4 } },
			    labelColor = { default={ 0 }, over={ 0, 0, 0 } },
			    strokeColor = { default={ 0, 0, 0 }, over={ 0.4, 0.1, 0.2 } },
			    strokeWidth = 1,
			    fontSize = 15,
			    shape = 'roundedRect',
			    cornerRadius = 10,
			    width = boxBg.width*.4,
			    height = boxBg.width*.25,
			    id = "setTemp",
			    label = "✓",
			    onEvent = handleSetTemp
			}
			tempChangeGroup:insert(confirmBtn)

			local cancelBtn = widget.newButton
			{
			    x=boxBg.x-boxBg.width*.25,
			    y=boxBg.y+boxBg.y*.5-boxBg.height*.14,
			    fillColor = { default={ .8,.4,.4 }, over={ .9,.3,.4 } },
			    labelColor = { default={ 0 }, over={ 0, 0, 0 } },
			    strokeColor = { default={ 0, 0, 0 }, over={ 0.4, 0.1, 0.2 } },
			    strokeWidth = 1,
			    fontSize = 15,
			    shape = 'roundedRect',
			    cornerRadius = 10,
			    width = boxBg.width*.4,
			    height = boxBg.width*.25,
			    id = "cancel",
			    label = "X",
			    onEvent = handleSetTemp
			}
			tempChangeGroup:insert(cancelBtn)


			local r =  20
			local r_x = math.sqrt(math.pow(r,2)-math.pow((r/2),2))
			local vertices = { 0,-r, r_x , r/2 , -r_x , r/2  }

			local function changeTemp(event)
				if event.phase == 'ended' then
					if event.target.id == 'cool' and thermoSetAt > 67 then
						thermoSetAt = thermoSetAt - 1
					elseif event.target.id == 'heat' and thermoSetAt < 78 then
						thermoSetAt = thermoSetAt + 1
					end
					currentSet.text = thermoSetAt.."°"
				end
			end

			local coolDown = display.newPolygon(tempChangeGroup, boxBg.x-boxBg.width*.18, boxBg.y-boxBg.height*.2, vertices )
			coolDown.id = 'cool'
			coolDown.rotation = -90
			coolDown:setFillColor(.2,.2,.9)
			coolDown:addEventListener('touch', changeTemp)

			local heatUp = display.newPolygon(tempChangeGroup, boxBg.x+boxBg.width*.18, boxBg.y-boxBg.height*.2, vertices )
			heatUp.id = 'heat'
			heatUp.rotation = 90
			heatUp:setFillColor(.9,.2,.2)
			heatUp:addEventListener('touch', changeTemp)
		end
	end

	local thermostatSetBlock = display.newRoundedRect(sceneGroup, padding+blockWidth+padding, blockWidth+padding*2, blockWidth, blockWidth, 2)
	thermostatSetBlock.anchorX = 0
	thermostatSetBlock.anchorY = 0
	thermostatSetBlock:setFillColor(.2,.7,.9)
	thermostatSetBlock:addEventListener('touch', controlTemp)

	local thermostatSetTitle = display.newText(sceneGroup, "Set", thermostatSetBlock.x+thermostatSetBlock.width*.5, thermostatSetBlock.y+thermostatSetBlock.height*.2, native.systemFont, 14)
	thermostatSetTitle:setFillColor(1)

	thermostatSetText = display.newText(sceneGroup, "*", thermostatSetBlock.x+thermostatSetBlock.width*.5, thermostatSetBlock.y+thermostatSetBlock.height*.62, native.systemFontBold, 30)
	thermostatSetText:setFillColor(1)
	-- end thermostat/temperature blocks 
	-- Mode block configuration -- 

	function modeSelected(event)
		if (event.phase == 'ended') then
			popupEngaged = true
			popupGroup = display.newGroup()
			local popBg = display.newRect(popupGroup, _W*.5, _H*.5, _W, _H)
			popBg:setFillColor(0,0,0,.85)
			popBg:addEventListener('touch', function() return true end)
			popBg:addEventListener('tap', function() return true end)

			local popupBox = display.newRoundedRect(popupGroup, _W*.5, _H*.5, _H*.8, _H*.9, 5)
			popupBox:setFillColor(.9)

			local popupEntry = display.newRoundedRect(popupGroup, popupBox.x, popupBox.y-popupBox.height*.3, popupBox.width*.9, popupBox.height*.12, 4)
			popupEntry:setFillColor(.5,.4,.6)

			popupEntryText = native.newTextBox(popupEntry.x, popupEntry.y, popupEntry.width*.8, popupEntry.height*.8)
			popupEntryText.hasBackground = false
			popupEntryText.font = native.newFont("Helvetica-Bold", 22)
			popupEntryText.align = 'center'
			popupEntryText.isEditable = false
			local function setTextBox()
				if(currentMode == 0) then
					popupEntryText.text = '*DISARMED*'
				elseif(currentMode == 1) then
					popupEntryText.text = '*ARMED HOME*'
				elseif(currentMode == 2) then
					popupEntryText.text = '*ARMED*'
				end
			end
			setTextBox()

			local popupTitle = display.newText(popupGroup, "Security Panel", popupBox.x, popupBox.y-popupBox.height*.45, native.systemFontBold, 20)
			popupTitle:setFillColor(0)

			local buttons = {1,2,3,4,5,6,7,8,9,0}

			local startX = popupBox.x - 90
			local startY = popupBox.y - 30

			local moveX = 0
			local moveY = 0

			local pinInput = ""
			for i=1,#buttons do
				local numberBg = display.newRoundedRect(popupGroup, startX + moveX, startY + moveY, 45, 45, 4)
				numberBg:setFillColor(.3)

				local function pinPress(event)
					if event.phase == 'ended' and string.len(pinInput) < 4 then
						pinInput = pinInput .. i
						
						local printOut = ""
						for i=1,string.len(pinInput) do
							printOut = printOut .. "*"
						end
						popupEntryText.text = printOut
						
					end
				end
				numberBg:addEventListener('touch', pinPress)
				
				local text = display.newText(popupGroup, buttons[i], numberBg.x, numberBg.y, native.systemFontBold, 20)
				text:setFillColor(1)
				if i == 3 or i == 6 then
					moveX = 0
					moveY = moveY + 48
				elseif i == 9 then
					moveX = moveX - 48
					moveY = moveY + 48
				else
					moveX = moveX + 48
				end
			end

			local function closeWindow()
				popupGroup:removeSelf()
				popupEntryText:removeSelf()
				popupGroup = nil
				popupEntryText = nil
				popupEngaged = false
			end

			-- Function for handling the arming and disarming system calls. It is setup to only let the user escape the window
			-- if the system is already disarmed. This window is default when the system is armed, unless disarmed.
			local function handleArmCondition(event)
				local call = event.target.id
				
				if event.phase == 'ended' then
					local hash = crypto.digest( crypto.md5, pinInput )
					pinInput = ""
					popupEntryText.text = ""
					if call == 0 and currentMode == 0 then
						closeWindow()
					elseif call == 0 then
						setTextBox()
					elseif call == 1 then
						local function domoticzArmHandler(event)
							if event.isError then
								print("Error")
							else
								local res = json.decode(event.response)
								if res.status == 'ERROR' then
									print("Invalid pin received. Making an input log")
									setTextBox()
								elseif res.status == "OK" then
									print("System armed")
									popupEntryText.text = "*ARMED*"
									currentMode = 1
								end
							end
						end
						network.request( beginUrl.."/json.htm?type=command&param=setsecstatus&secstatus=2&seccode="..hash, "GET", domoticzArmHandler )
					elseif call == 2 then
						local function domoticzDisableHandler(event)
							if event.isError then
								print("Error")
								setTextBox()
							else
								local res = json.decode(event.response)
								if res.status == 'ERROR' then
									-- code was wrong
									print("Error")
									setTextBox()
								elseif res.status == "OK" then
									-- code was right, change was made
									print("System disarmed")
									popupEntryText.text = "*DISARMED*"
									currentMode = 0
									--timer.performWithDelay(1000, closeWindow)
								end
							end
						end
						network.request( beginUrl.."/json.htm?type=command&param=setsecstatus&secstatus=0&seccode="..hash, "GET", domoticzDisableHandler )
					end
				end
			end

			
			local disarmBtn = display.newRoundedRect(popupGroup, startX+(42*4), startY, 90, 45, 3)
			disarmBtn:setFillColor(.2,.8,.2,.7)
			disarmBtn:setStrokeColor( 0, 0, 0 )
			disarmBtn.strokeWidth = 2
			disarmBtn.id = 2
			disarmBtn:addEventListener('touch', handleArmCondition)
			local disarmBtnText = display.newText(popupGroup, "DISARM", disarmBtn.x, disarmBtn.y, "Helvetica-Bold", 14)
			disarmBtnText:setFillColor(0)

			local cancelBtn = display.newRoundedRect(popupGroup, startX+(42*4), startY + 48, 90, 45, 3)
			cancelBtn:setFillColor(.2,.2,.8,.7)
			cancelBtn:setStrokeColor( 0, 0, 0 )
			cancelBtn.strokeWidth = 2
			cancelBtn.id = 0
			cancelBtn:addEventListener('touch', handleArmCondition)

			local cancelBtnText = display.newText(popupGroup, "CANCEL", cancelBtn.x, cancelBtn.y, "Helvetica-Bold", 14)
			cancelBtnText:setFillColor(0)

			local armBtn = display.newRoundedRect(popupGroup, startX+(42*4), startY + 48*2, 90, 45, 3)
			armBtn:setFillColor(.8,.2,.2,.7)
			armBtn:setStrokeColor( 0, 0, 0 )
			armBtn.strokeWidth = 2
			armBtn.id = 1
			armBtn:addEventListener('touch', handleArmCondition)
			local armBtnText = display.newText(popupGroup, "ARM", armBtn.x, armBtn.y, "Helvetica-Bold", 14)
			armBtnText:setFillColor(0)
		end
	end
	local currentModeBlock = display.newRoundedRect(sceneGroup, padding, blockWidth*2+padding*3, blockWidth*2+padding, blockWidth, 2)
	currentModeBlock.anchorX = 0
	currentModeBlock.anchorY = 0
	currentModeBlock:setFillColor(.5,.2,1)
	currentModeBlock:addEventListener('touch', modeSelected)

	local modeBlockTitle = display.newText(sceneGroup, "Security Mode", currentModeBlock.x+currentModeBlock.width*.5, currentModeBlock.y+currentModeBlock.height*.25, native.systemFont, 14)
	modeBlockTitle:setFillColor(1)

	modeBlockText = display.newText(sceneGroup, "N/A", currentModeBlock.x+currentModeBlock.width*.5, currentModeBlock.y+currentModeBlock.height*.65, native.systemFontBold, 22)
	
	---- END MODE BLOCK -- 
	-- Begin Sleep activation --

	local function onSelect(event)
		if event.phase == 'began' then
			event.target:setFillColor(.4)
		elseif event.phase == 'moved' then
			event.target:setFillColor(.6)
		elseif event.phase == 'ended' then
			if sleepActive == false and currentMode == 0 then
				local function sleepHandlerOn(event)
					if event.isError then
						print("Error")
					else
						sleepActive = true
						sleepBlock:setFillColor(.3,.3,.8)
					end
				end
				-- Had the security code hash hard-coded. Might need to find another way to handle this, add pad popup, or remove the functionality.
				--network.request( beginUrl.."/json.htm?type=command&param=setsecstatus&secstatus=1&seccode=".."HASH HERE", "GET", sleepHandlerOn )
			elseif currentMode == 1 then
				local function sleepHandlerOff(event)
					if event.isError then
						print("Error")
					else
						sleepActive = false
						sleepBlock:setFillColor(.6)
					end
				end
				
				--network.request( beginUrl.."/json.htm?type=command&param=setsecstatus&secstatus=0&seccode=".."HASH HERE", "GET", sleepHandlerOff )
			else
				event.target:setFillColor(.6)
			end
		end
		return true
	end

	sleepBlock = display.newRoundedRect(sceneGroup, blockWidth*6+padding*5, blockWidth*3+padding*4, blockWidth, blockWidth, 2 )
	sleepBlock.anchorX = 0
	sleepBlock.anchorY = 0
	sleepBlock:addEventListener("touch", onSelect)

	sleepBlock:setFillColor(.6)

	local sleepTitle =  display.newText(sceneGroup, "Good Night", sleepBlock.x+sleepBlock.width*.5, sleepBlock.y+sleepBlock.height*.2, native.systemFont, 12 )
	sleepTitle:setFillColor( 1 )

	local moon = display.newImage(sceneGroup, "Images/moon.png")
	moon:scale(.5,.5)
	moon.x = sleepBlock.x+sleepBlock.width*.5
	moon.y = sleepBlock.y+sleepBlock.height*.6

	-- End sleep activation --
	-- Camera view --
	local function onCameraSelect(event)
		if event.phase == 'ended' then

			local cameraGroup = display.newGroup()
			local images = {}
			local isCancelled = false

	    	local function closeCamView(event)
    			if event.phase == 'ended' then
    				cameraGroup:removeSelf()
    				images = nil
    				isCancelled = true
    			end
    			return true
			end

			local function refreshPictures(event)
				if event.phase == 'ended' then
					cameraGroup:removeSelf()
					onCameraSelect({phase='ended'})
				end
				return true
			end

			local blackBg = display.newRect(cameraGroup, _W*.5, _H*.5, _W, _H)
    		blackBg:setFillColor(0,0,0,.8)
    		
    		blackBg:addEventListener('touch', function() return true end)

	        local backBlock = display.newRoundedRect(cameraGroup, _W*.45, _H-blockWidth*.25-padding, blockWidth*.7, blockWidth*.5,5)
			backBlock:setFillColor(.7,.3,.3,.6)
			backBlock:addEventListener('touch', closeCamView)
			local backIcon = display.newImageRect(cameraGroup, 'Images/back.png', 35,35)
			backIcon.x = backBlock.x
			backIcon.y = backBlock.y
			local refreshBlock = display.newRoundedRect(cameraGroup, _W*.55, _H-blockWidth*.25-padding, blockWidth*.7, blockWidth*.5,5)
			refreshBlock:setFillColor(.3,.3,.7,.6)
			refreshBlock:addEventListener('touch', refreshPictures)
			local refreshIcon = display.newImageRect(cameraGroup, 'Images/refresh.png', 40,40)
			refreshIcon.x = refreshBlock.x
			refreshIcon.y = refreshBlock.y

			local function networkListener( event )

			    if ( event.isError ) then
			        print ( "Network error - download failed" )
			    else
			    	if(isCancelled and event.target) then
			    		event.target:removeSelf()
			    		event.target = nil
						return true
					end
			    	local place = tonumber(string.match (event.response.filename, "%d+"))
			    	if images[place] then
			    		images[place]:removeSelf()
			    		images[place] = null
		    		end
			    	images[place] = event.target
			    	cameraGroup:insert(images[place])

			    	
			    	local startX = 0
					local startY = 0

			    	if place == 2 then
			    		startX = _W*.5
		    		elseif place == 3 then
		    			startY = _H*.5
	    			elseif place == 4 then
	    				startX = _W*.5
	    				startY = _H*.5
		    		end

			    	images[place].alpha = 0
			        images[place].width=_W*.5
			        images[place].height=_H*.5
			        images[place].x=startX
			        images[place].y=startY
			        images[place].anchorX=0
			        images[place].anchorY=0
			        transition.to( images[place], { alpha = 1.0 } )
			        local isEnlarged = false
			        local holdX = images[place].x
			        local holdY = images[place].y

			        local function enlargeImage(event)
			        	if event.phase == 'ended' then
			        		if isEnlarged == false then
			        			images[place]:toFront()
			        			transition.to( images[place], { x=0,y=0,width = _W, height = _H } )
			        			isEnlarged = true
		        			else
		        				transition.to( images[place], { x=holdX, y=holdY, width = _W*.5, height = _H*.5 } )
		        				isEnlarged = false
		        				refreshBlock:toFront()
		        				backBlock:toFront()
		        				backIcon:toFront()
		        				refreshIcon:toFront()
	        				end
			        	end
			        	return true
			        end
			        images[place]:addEventListener('touch', enlargeImage)

			    	images[place]:toBack()
			    	blackBg:toBack()
			    end
			end

			for i=1,#cameraList do
				display.loadRemoteImage( "http://"..cameraList[i].."/cgi-bin/snapshot.cgi?loginuse=["..camUsername.."]&loginpas=["..camPassword.."]", "GET", networkListener, "cam-"..i..".png", system.TemporaryDirectory, 50, 50 )
				
				-- Testing the loading of a remote image when no camera is present
				--display.loadRemoteImage( "https://www.networkcameracritic.com/Dahua/ipc-hfw4300s%20night%20driveway%2020%20WDR2.jpg", "GET", networkListener, "cam-"..i..".png", system.TemporaryDirectory, 50, 50 )
			end
		end
	end

	cameraBlock = display.newRoundedRect(sceneGroup, padding, blockWidth*3+padding*4, blockWidth, blockWidth, 2 )
	cameraBlock.anchorX = 0
	cameraBlock.anchorY = 0
	cameraBlock:addEventListener("touch", onCameraSelect)

	cameraBlock:setFillColor(.1,.4,.9)

	local cameraTitle =  display.newText(sceneGroup, "Cameras", cameraBlock.x+cameraBlock.width*.5, cameraBlock.y+cameraBlock.height*.2, native.systemFont, 12 )
	cameraTitle:setFillColor( 1 )

	local camIcon = display.newImage(sceneGroup, "Images/cam.png")
	camIcon:scale(.4,.4)
	camIcon.x = cameraBlock.x+cameraBlock.width*.5
	camIcon.y = cameraBlock.y+cameraBlock.height*.6

	-- end camera view --
	-- Initialize devices --

	local isInitial = true
	local function pollScenes()
		local function networkListener( event )
			if ( event.isError ) then
				print("Network error!")
			else
				local response = json.decode(event.response)
				if isInitial == true then
					for i=1,#response.result do
						blockCreator(i, response.result[i])
					end
					isInitial = false
				else
					for i=1,#switchArray do
						if(switchArray[i].id == response.result[i].idx) then
							switchArray[i]:compareStates(response.result[i].Status)
						end
					end
			    end
			    timer.performWithDelay(1000, pollScenes)
			end
			
		end
		network.request( beginUrl.."/json.htm?type=scenes", "GET", networkListener )
	end
	pollScenes()

	-- end device initialization --
	-- Get thermostat information --

	local function pollThermostat()
		local function nestListener(event)
			if event.isError then
				print("Error talking with domoticz")
			else
				local res = json.decode(event.response)
				local res = res.result[1]

				local currentTemp = res.Data			

				local tempData = {};
				local word;

				for word in string.gmatch(currentTemp, "[^,]+") do
					tempData[#tempData+1] = word; -- save result in table
				end
				tempData[1] = string.gsub( tempData[1], " F", "" )
				tempData[1] = math.round(tempData[1]).."°"
				thermostatText.text = tempData[1]
				timer.performWithDelay(4000, pollThermostat)
			end
			
		end
		-- Used to get the current temperature from the thermostat
		network.request( beginUrl.."/json.htm?type=devices&rid="..temperatureId, "GET", nestListener)
	end
	pollThermostat()

	-- end thermostat --
	-- Begin setpoint grab --

	local function pollSetPoint()
		local function nestListener(event)
			if event.isError then
				print("Error talking with domoticz")
			else
				local res = json.decode(event.response)
				local res = res.result[1].SetPoint
				local set = math.round(res)
				thermostatSetText.text = set.."°"
				thermoSetAt = set
				timer.performWithDelay(4000, pollSetPoint)
			end
			
		end
		network.request( beginUrl.."/json.htm?type=devices&rid="..thermostatId, "GET", nestListener)
	end
	pollSetPoint()

	if thermoSetAt == nil then
		thermoSetAt = 76
	end

	-- end setpoint grab --	
end

function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	local lastCondition = os.time()

	if phase == "will" then
	elseif phase == "did" then
		-- Keep the time updated
		local function updateTime()
			local timeStamp = os.date("*t")
			dateBlockDate.text = timeStamp.day.." "..os.date("%b").." "..timeStamp.year
			dateBlockTime.text = os.date("%I")..":"..string.format( "%02d", timeStamp.min ) .. " " ..os.date("%p")
			timer.performWithDelay(10000, updateTime)
		end
		updateTime()
		-- END KEEPING TIME UPDATE --
		-- BEGIN UPDATE FOR SECURITY --
		local function updateSecurity()
			local function secStatus(event)
				if(event.isError) then
					print("Network error on sec status update")
				else
					local res = json.decode(event.response)
					if res.status == "OK" then
						if res.secstatus == 0 then
							currentMode = 0
							if sleepActive == true then
								sleepActive = false
								sleepBlock:setFillColor(.6)
							end
							modeBlockText.text = "DISARMED"
							if popupGroup and popupEntryText then
								popupEntryText.text = '*DISARMED*'
							end
						elseif res.secstatus == 1 then
							currentMode = 1
							modeBlockText.text = "SLEEP"
							if sleepActive == false then
								sleepActive = true
								sleepBlock:setFillColor(.3,.3,.8)
							end	
							if popupEngaged == false then
								local t = {phase = 'ended'}
								modeSelected(t)
							end						
						elseif res.secstatus == 2 then
							currentMode = 2
							if sleepActive == true then
								sleepActive = false
								sleepBlock:setFillColor(.6)
							end
							if popupEngaged == false then
								local t = {phase = 'ended'}
								modeSelected(t)
							end		
							modeBlockText.text = 'ARMED'
						end
					end
					timer.performWithDelay(1000, updateSecurity)
				end
				
			end
			network.request( beginUrl.."/json.htm?type=command&param=getsecstatus", "GET", secStatus )
		end
		updateSecurity()
		-- END UPDATE FOR SECURITY --
		-- BEGIN WEATHER POLLING --
		local function forecastUpdate()
			local function weatherHandler(event)
				if event.isError then
					print("Error grabbing weather")
				else 
					--print(event.response)
					local res = json.decode(event.response)
					local today = res.forecast.simpleforecast.forecastday[1]
					local tomorrow = res.forecast.simpleforecast.forecastday[2]

					local iconX = tomIcon.x
					local iconY = tomIcon.y

					tomIcon:removeSelf()
					if tomorrow.icon == "clear" or tomorrow.icon == 'sunny' or tomorrow.icon == 'unknown' then
						tomIcon = display.newImageRect(sceneGroup, "Images/weather/Sunny.png", 35, 35)
					elseif tomorrow.icon == "mostlycloudy" or tomorrow.icon == "mostlysunny" or tomorrow.icon == "partlycloudy" or tomorrow.icon == "partlysunny" then
						tomIcon = display.newImageRect(sceneGroup, "Images/weather/Mostly Cloudy.png", 35, 35)
					elseif tomorrow.icon == "cloudy" then
						tomIcon = display.newImageRect(sceneGroup, "Images/weather/Cloudy.png", 35, 35)
					elseif tomorrow.icon == "tstorms" or tomorrow.icon == 'chancetstorms' then
						tomIcon = display.newImageRect(sceneGroup, "Images/weather/Thunderstorms.png", 35, 35)
					elseif tomorrow.icon == "chancerain" then
						tomIcon = display.newImageRect(sceneGroup, "Images/weather/Slight Drizzle.png", 35, 35)
					elseif tomorrow.icon == "rain" then
						tomIcon = display.newImageRect(sceneGroup, "Images/weather/Drizzle.png", 35, 35)
					elseif tomorrow.icon == "haze" or tomorrow.icon == 'fog' then
						tomIcon = display.newImageRect(sceneGroup, "Images/weather/Haze.png", 35, 35)
					elseif tomorrow.icon == "snow" or tomorrow.icon == 'flurries' or tomorrow.icon == 'sleet' or tomorrow.icon == 'chancesleet' or tomorrow.icon == 'chanceflurries' or tomorrow.icon == 'chancesnow' then
						tomIcon = display.newImageRect(sceneGroup, "Images/weather/Snow.png", 35, 35)
					end

					tomIcon.x = iconX
					tomIcon.y = iconY

					todayHighLow.text = today.high.fahrenheit.."°/"..today.low.fahrenheit.."°"
					todayPop.text = today.pop.."%"

					tomHighLow.text = tomorrow.high.fahrenheit.."°/"..tomorrow.low.fahrenheit.."°"
					tomPop.text = tomorrow.pop.."%"
				end
			end	
			network.request( "http://api.wunderground.com/api/"..wuApi.."/forecast/q/"..myState.."/"..myCity..".json", "GET", weatherHandler)
		end
		forecastUpdate()

		local function conditionsUpdate()
			lastCondition = os.time()
			local function weatherHandler(event)
				if event.isError then
					print("Error grabbing weather")
				else
					local res = json.decode(event.response)
					local res = res.current_observation
					
					local iconX = dailyIcon.x
					local iconY = dailyIcon.y
					dailyIcon:removeSelf()

					if res.icon == "clear" or res.icon == 'sunny' or res.icon == 'unknown' then
						dailyIcon = display.newImageRect(sceneGroup, "Images/weather/Sunny.png", 55, 55)
					elseif res.icon == "mostlycloudy" or res.icon == "mostlysunny" or res.icon == "partlycloudy" or res.icon == "partlysunny" then
						dailyIcon = display.newImageRect(sceneGroup, "Images/weather/Mostly Cloudy.png", 55, 55)
					elseif res.icon == "cloudy" then
						dailyIcon = display.newImageRect(sceneGroup, "Images/weather/Cloudy.png", 55, 55)
					elseif res.icon == "tstorms" or res.icon == 'chancetstorms' then
						dailyIcon = display.newImageRect(sceneGroup, "Images/weather/Thunderstorms.png", 55, 55)
					elseif res.icon == "chancerain" then
						dailyIcon = display.newImageRect(sceneGroup, "Images/weather/Slight Drizzle.png", 55, 55)
					elseif res.icon == "rain" then
						dailyIcon = display.newImageRect(sceneGroup, "Images/weather/Drizzle.png", 55, 55)
					elseif res.icon == "haze" or res.icon == 'fog' then
						dailyIcon = display.newImageRect(sceneGroup, "Images/weather/Haze.png", 55, 55)
					elseif res.icon == "snow" or res.icon == 'flurries' or res.icon == 'sleet' or res.icon == 'chancesleet' or res.icon == 'chanceflurries' or res.icon == 'chancesnow' then
						dailyIcon = display.newImageRect(sceneGroup, "Images/weather/Snow.png", 55, 55)
					end

					dailyIcon.x = iconX
					dailyIcon.y = iconY

					currentTemp.text = res.temp_f.."°"
				end
			end
			network.request( "http://api.wunderground.com/api/"..wuApi.."/conditions/q/"..myState.."/"..myCity..".json", "GET", weatherHandler)
		end
		conditionsUpdate()

		-------- RUNTIME METHOD --------
		local maxTime = 60
		local function checkTime(event)
			local now = os.time()
			if ( now > lastCondition + maxTime ) then
				conditionsUpdate()
				forecastUpdate()
			end
		end
		Runtime:addEventListener("enterFrame", checkTime)

		-- END WEATHER POLLING --
	end	
end

function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if event.phase == "will" then

	elseif phase == "did" then
	end
end

function scene:destroy( event )
	local sceneGroup = self.view
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene