-----------------------------------------------------------------------------------------
--
-- main.lua
-- Developer: Justin Breed; All Rights Reserved.
--
-----------------------------------------------------------------------------------------
system.setIdleTimer( true )
display.setStatusBar( display.HiddenStatusBar )

local widget = require "widget"
local composer = require "composer"

-- Sets width and height of phone to global variables
_W = display.contentWidth
_H = display.contentHeight

-- Sets beginning part of the URL where domoticz is hosted to include login information
beginUrl = "http://username:password@192.168.X.X:8080"

-- Sets the city and state that is used when polling weather underground
myCity = "CITY"
myState = "STATE"
wuApi = "API_HERE"

-- List of IP cameras used for the camera button to populate from
cameraList = {'192.168.X.X', '192.168.X.X', '192.168.X.X', '192.168.X.X'}
camUsername = 'user'
camPassword = 'password'

-- Domoticz device IDs
temperatureId = 14
thermostatId = 13


-- event listeners for tab buttons:
local function onFirstView( event )
	composer.gotoScene( "screen1" )
end


onFirstView()	-- invoke loading the application interface screen