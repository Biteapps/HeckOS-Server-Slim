
local GUI = require("GUI")
local screen = require("Screen")
local filesystem = require("Filesystem")
local color = require("Color")
local image = require("Image")
local paths = require("Paths")
local system = require("System")
local text = require("Text")
local internet = require("Internet")
local event = require("Event")

--------------------------------------------------------------------------------

local currentScriptDirectory = filesystem.path(system.getCurrentScript())

local function loadImage(name)
	local result, reason = image.load(currentScriptDirectory .. "Images/" .. name .. ".pic")

	if not result then
		GUI.alert(reason)
	end

	return result
end

local speedSlider
local speedMin = 0.25
local speedMax = 1.75

local bpmMin = 40
local bpmMax = 200

local powerButton

local tapes
local tapeIndex
local tape
local tapeWritingProgress

local function updateCurrentTapeSpeed()
	component.invoke(tape.address, "setSpeed", speedMin + tape.speed * (speedMax - speedMin))
end

local function updateCurrentTape()
	tape = tapes[tapeIndex]
	speedSlider.value = tape.speed

	updateCurrentTapeSpeed()
end

local function incrementTape(next)
	tapeIndex = tapeIndex + (next and 1 or -1)

	if tapeIndex > #tapes then
		tapeIndex = 1
	elseif tapeIndex < 1 then
		tapeIndex = #tapes
	end

	updateCurrentTape()
end

local function updateTapes()
 	tapes = {}
 	tapeIndex = 1

 	for address in component.list("tape_drive") do
 		table.insert(tapes, {
 			address = address,
 			size = component.invoke(address, "getSize"),
 			speed = 0.5,
 			cues = {},
 		})
 	end

 	updateCurrentTape()
end

-------------------------------- Round mini button ------------------------------------------------

local function roundMiniButtonDraw(button)
	local bg, fg = button.animationCurrentBackground, powerButton.pressed and button.animationCurrentText or 0x0

	-- Background
	screen.drawRectangle(button.x + 1, button.y + 1, button.width - 2, button.height - 2, bg, fg, " ")

	-- Upper
	screen.drawText(button.x + 1, button.y, bg, string.rep("⣀", button.width - 2))

	-- Left
	screen.drawText(button.x, button.y + 1, bg, "⢸")

	-- Middle
	screen.drawText(math.floor(button.x + button.width / 2 - #button.text / 2), button.y + 1, fg, button.text)

	-- Right
	screen.drawText(button.x + button.width - 1, button.y + 1, bg, "⡇")

	-- Lower
	screen.drawText(button.x + 1, button.y + button.height - 1, bg, string.rep("⠉", button.width - 2))
end


local function roundMiniButtonEventHandler(workspace, button, e1, e2, e3, e4, e5)
	if e1 == "touch" then
		button:press()
	end
end

local function newRoundMiniButton(x, y, ...)
	local button = GUI.button(x, y, 4, 3, ...)

	button.draw = roundMiniButtonDraw
	button.eventHandler = roundMiniButtonEventHandler

	return button
end


local function roundTinyButtonDraw(button)
	local bg, fg = button.animationCurrentBackground, powerButton.pressed and button.animationCurrentText or 0x0

	-- Left
	screen.drawText(button.x, button.y, bg, "⢰")

	-- Middle
	screen.drawRectangle(button.x + 1, button.y, 2, 1, bg, fg, " ")
	screen.drawText(button.x + 1, button.y, fg, button.text)

	-- Right
	screen.drawText(button.x + 3, button.y, bg, "⡆")

	-- Lower
	screen.drawText(button.x, button.y + 1, bg, "⠈⠛⠛⠁")

	-- -- Left
	-- screen.drawText(button.x, button.y, bg, "⣾")

	-- -- Middle
	-- screen.set(button.x + 1, button.y, bg, fg, "⠄")

	-- -- Right
	-- screen.drawText(button.x + 2, button.y, bg, "⡆")

	-- -- Lower
	-- screen.drawText(button.x, button.y + 1, bg, "⠈⠉")
end

local function newRoundTinyButton(x, y, ...)
	local button = GUI.button(x, y, 4, 2, ...)

	button.draw = roundTinyButtonDraw
	button.eventHandler = roundMiniButtonEventHandler

	return button
end

-------------------------------- UpperButtons ------------------------------------------------

local function upperButtonDraw(button)
	local bg, fg = button.animationCurrentBackground, powerButton.pressed and button.animationCurrentText or 0x0

	-- Background
	screen.drawRectangle(button.x + 1, button.y + 1, button.width - 2, button.height - 2, bg, fg, " ")

	-- Upper
	screen.drawText(button.x, button.y, fg, "⢀" .. string.rep("⣀", button.width - 2) .. "⡀")

	-- Left
	screen.drawText(button.x, button.y + 1, fg, "⢸")

	-- Middle
	screen.drawText(math.floor(button.x + button.width / 2 - unicode.len(button.text) / 2), button.y + 1, fg, button.text)

	-- Right
	screen.drawText(button.x + button.width - 1, button.y + 1, fg, "⡇")

	-- Lower
	screen.drawText(button.x, button.y + button.height - 1, fg, "⠈" .. string.rep("⠉", button.width - 2) .. "⠁")

end

local function upperButtonEventHandler(workspace, button, e1, e2, e3, e4, e5)
	if e1 == "touch" and powerButton.pressed then
		button:press()
	end
end

local function newUpperButton(x, y, width, ...)
	local button = GUI.button(x, y, width, 3, ...)

	button.pressed = false
	button.draw = upperButtonDraw
	button.eventHandler = upperButtonEventHandler

	return button
end

-------------------------------- Round mini button ------------------------------------------------

local function hotCueButtonDraw(button)
	local bg, fg = button.animationCurrentBackground, powerButton.pressed and button.animationCurrentText or 0x2D2D2D

	-- Upper
	screen.drawText(button.x, button.y, bg, "⢀" .. string.rep("⣀", button.width - 2) .. "⡀")

	-- Left
	screen.drawText(button.x, button.y + 1, bg, "⢸")

	-- Middle
	screen.set(button.x + 1, button.y + 1, 0x2D2D2D, 0x5A5A5A, "⣤")
	screen.set(button.x + 2, button.y + 1, bg, 0x787878, "⠤")

	screen.set(button.x + 3, button.y + 1, bg, fg, button.text)

	screen.set(button.x + 4, button.y + 1, bg, 0x787878, "⠒")
	screen.set(button.x + 5, button.y + 1, 0x2D2D2D, 0x5A5A5A, "⠛")

	-- Right
	screen.drawText(button.x + button.width - 1, button.y + 1, bg, "⡇")

	-- Lower
	screen.drawText(button.x, button.y + button.height - 1, bg, "⠈" .. string.rep("⠉", button.width - 2) .. "⠁")

end

local function hotCueButtonEventHandler(workspace, button, e1, e2, e3, e4, e5)
	if e1 == "touch" then
		button:press()
	end
end

local function newHotCueButton(x, y, defaultForeground, pressedForeground, text)
	local button = GUI.button(x, y, 7, 3, 0x1E1E1E, defaultForeground, 0x0, pressedForeground, text)

	button.draw = hotCueButtonDraw
	button.eventHandler = hotCueButtonEventHandler

	return button
end


-------------------------------- Window ------------------------------------------------

local backgroundImage = loadImage("Background")

local workspace, window, menu = system.addWindow(GUI.window(1, 1, 78, 49))

window.drawShadow = false



-------------------------------- Jog ------------------------------------------------

local jogImages = {}

for i = 1, 12 do
	jogImages[i] = loadImage("Jog" .. i)
end


local function getIsPlaying()
	return component.invoke(tape.address, "getState") == "PLAYING"
end

-------------------------------- Background ------------------------------------------------

local windowBackground = window:addChild(GUI.object(1, 1, window.width, window.height))

local currentJogIndex = 1
local displayWidth, displayHeight = 33, 9

local function displayDrawProgressBar(x, y, width, progress)
	local progressActiveWidth = math.floor(progress * width)

	screen.drawText(x, y, 0xE1E1E1, string.rep("━", progressActiveWidth))
	screen.drawText(x + progressActiveWidth, y, 0x4B4B4B, string.rep("━", width - progressActiveWidth))
end

windowBackground.draw = function(windowBackground)
	-- Background
	screen.drawImage(windowBackground.x, windowBackground.y, backgroundImage)
	
	-- Ignoring if power is off
	if not powerButton.pressed then
		return
	end

	-- Power indicator
	screen.drawText(windowBackground.x + 73, windowBackground.y + 3, 0xFF0000, "●")

	-- Speed slider indicator
	screen.drawText(windowBackground.x + 68, windowBackground.y + 39, 0xFFDB40, "⠆")

	-- Jog
	screen.drawImage(windowBackground.x + 33, windowBackground.y + 29, jogImages[currentJogIndex])

	-- Display
	local displayX, displayY = windowBackground.x + 22, windowBackground.y + 3
	local displayUpperText

	if tapeWritingProgress then
		displayUpperText = "Writing in progress"

		local progressWidth = displayWidth - 4

		displayDrawProgressBar(
			math.floor(displayX + displayWidth / 2 - progressWidth / 2),
			math.floor(displayY + displayHeight / 2),
			progressWidth,
			tapeWritingProgress
		)
	else
		-- UpperText
		displayUpperText = component.invoke(tape.address, "getLabel")

		if not displayUpperText or #displayUpperText == 0 then
			displayUpperText = "Untitled tape"
		end

		-- BPM
		local bpmText = tostring(math.floor(bpmMin + speedSlider.value * (bpmMax - bpmMin))) .. " bpm"
		local bpmWidth = #bpmText + 4
		
		local bpmX = displayX + displayWidth - 2 - bpmWidth
		local bpmY = displayY + displayHeight - 5

		screen.drawFrame(bpmX, bpmY, bpmWidth, 3, 0xE1E1E1)
		screen.drawText(bpmX + 2, bpmY + 1, 0xE1E1E1, bpmText)

		-- Lower track
		local progressWidth = displayWidth - 4

		displayDrawProgressBar(
			math.floor(displayX + displayWidth / 2 - progressWidth / 2),
			displayY + displayHeight - 2,
			progressWidth,
			tape.size == 0 and 0 or component.invoke(tape.address, "getPosition") / tape.size
		)
	end

	-- UpperText
	displayUpperText = text.limit(displayUpperText, displayWidth - 2)
	screen.drawText(math.floor(displayX + displayWidth / 2 - #displayUpperText / 2), displayY + 1, 0xE1E1E1, displayUpperText)
end

-------------------------------- Power button ------------------------------------------------

powerButton = window:addChild(GUI.object(75, 2, 4, 2))

powerButton.pressed = false

powerButton.draw = function()
	screen.drawText(powerButton.x, powerButton.y, 0x1E1E1E, powerButton.pressed and "⣠⣤⣄" or "⣸⣿⣇")
end

powerButton.eventHandler = function(workspace, powerButton, e1)
	if e1 == "touch" then
		powerButton.pressed = not powerButton.pressed

		-- Stopping playback
		if powerButton.pressed then
			currentJogIndex = 1
		else
			for i = 1, #tapes do
				component.invoke(tapes[i].address, "stop")
			end
		end

		workspace:draw()

		computer.beep(20, 0.01)
	end
end

-------------------------------- ImageButton ------------------------------------------------

local imageButtonBlink = false
local imageButtonBlinkUptime = 0
local imageButtonBlinkInterval = 0.5

local function imageButtonDraw(button)
	screen.drawImage(button.x, button.y, (powerButton.pressed and (not button.blinking or imageButtonBlink)) and button.imageOn or button.imageOff)
end

local function newImageButton(x, y, width, height, name)
	local button = GUI.object(x, y, width, height)

	button.imageOn = loadImage(name .. "On")
	button.imageOff = loadImage(name .. "Off")

	button.draw = imageButtonDraw

	return button
end


-------------------------------- Speed slider ------------------------------------------------

local speedSliderImage = loadImage("SpeedSlider")

speedSlider = window:addChild(GUI.object(71, 33, 5, 14))

speedSlider.draw = function(speedSlider)
	-- screen.drawRectangle(speedSlider.x, speedSlider.y, speedSlider.width, speedSlider.height, 0xFF0000, 0x0, " ")

	local x = speedSlider.x
	local y = speedSlider.y + math.floor((1 - speedSlider.value) * (speedSlider.height - image.getHeight(speedSliderImage) / 2))

	screen.drawImage(x, y, speedSliderImage)
end

speedSlider.eventHandler = function(workspace, speedSlider, e1, e2, e3, e4)
	if e1 == "touch" or e1 == "drag" then
		speedSlider.value = 1 - ((e4 - speedSlider.y) / speedSlider.height)
		tape.speed = speedSlider.value

		updateCurrentTapeSpeed()

		workspace:draw()
	end
end

-------------------------------- File/url/label upper buttons ------------------------------------------------

local _ = window:addChild(newUpperButton(14, 1, 7, 0x1E1E1E, 0xF0F0F0, 0x0F0F0F, 0xA5A5A5, "Help"))
local urlUpperButton = window:addChild(newUpperButton(14, 4, 7, 0x1E1E1E, 0x3349FF, 0x0F0F0F, 0x002480, "Url"))
local fileUpperButton = window:addChild(newUpperButton(14, 7, 7, 0x1E1E1E, 0xFFDB40, 0x0F0F0F, 0x996D00, "File"))

local _ = window:addChild(newRoundTinyButton(14, 12, 0x0F0F0F, 0xFF0000, 0x0F0F0F, 0xFF0000, "⢠⡄"))
local _ = window:addChild(newRoundTinyButton(18, 12, 0x0F0F0F, 0x2D2D2D, 0x0F0F0F, 0x2D2D2D, "⢠⡄"))

local labelUpperButton = window:addChild(newUpperButton(23, 1, 9, 0x1E1E1E, 0xFFDB40, 0x0F0F0F, 0x996D00, "Label"))
local _ = window:addChild(newUpperButton(33, 1, 9, 0x1E1E1E, 0xFFDB40, 0x0F0F0F, 0x996D00, " "))
local _ = window:addChild(newUpperButton(43, 1, 9, 0x1E1E1E, 0xFFDB40, 0x0F0F0F, 0x996D00, " "))

fileUpperButton.onTouch = function()
	local filesystemDialog = GUI.addFilesystemDialog(workspace, true, 50, math.floor(window.height * 0.8), "Confirm", "Cancel", "File name", "/")
	
	filesystemDialog:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
	filesystemDialog:addExtensionFilter(".dfpwm")
	filesystemDialog:expandPath(paths.user.desktop)
	filesystemDialog:show()

	filesystemDialog.onSubmit = function(path)
		local tapeSpaceFree = tape.size - component.invoke(tape.address, "getPosition")
		local fileSize = filesystem.size(path)

		if fileSize > tapeSpaceFree then
			GUI.alert("Not enough space on tape")
			return
		end
		
		local file = filesystem.open(path, "rb")

		component.invoke(tape.address, "stop")

		local bytesWritten, chunk = 0
		while true do
			chunk = file:read(8192)

			if not chunk then
				break
			end

			if not component.invoke(tape.address, "isReady") then
				GUI.alert("Tape was removed during writing")
				break
			end

			component.invoke(tape.address, "write", chunk)

			bytesWritten = bytesWritten + #chunk
			tapeWritingProgress = bytesWritten / fileSize
			workspace:draw()
		end

		file:close()
		component.invoke(tape.address, "seek", -tape.size)
		tapeWritingProgress = nil
	end
end

urlUpperButton.onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, title)
	
	local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x969696, 0xE1E1E1, 0x2D2D2D, "", "Url", false))

	input.onInputFinished = function()
		

		workspace:draw()
	end

	container.panel.onTouch = function()
		container:remove()
		workspace:draw()
	end

	workspace:draw()

	return container
end

labelUpperButton.onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, title)
	
	local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x969696, 0xE1E1E1, 0x2D2D2D, component.invoke(tape.address, "getLabel") or "", "New label", false))

	input.onInputFinished = function()
		component.invoke(tape.address, "setLabel", input.text)
		workspace:draw()
	end

	container.panel.onTouch = function()
		container:remove()
		workspace:draw()
	end

	workspace:draw()

	return container
end

-------------------------------- Needle search ------------------------------------------------

local needleSearch = window:addChild(GUI.object(25, 15, 29, 2))

needleSearch.draw = function()
	-- screen.drawRectangle(needleSearch.x, needleSearch.y, needleSearch.width, needleSearch.height, 0xFF0000, 0x0, " ")

	screen.drawText(needleSearch.x, needleSearch.y, powerButton.pressed and 0xE1E1E1 or 0x0, "▲ ╷ ╷ ╷ ╷ ╷ ╷ ╷ ╷ ╷ ╷ ╷ ╷ ╷ ▲")
end

needleSearch.eventHandler = function(workspace, needleSearch, e1, e2, e3, e4)
	if e1 == "touch" and powerButton.pressed and tape then
		local position = component.invoke(tape.address, "getPosition")
		local newPosition = math.floor((e3 - needleSearch.x) / needleSearch.width * tape.size)

		component.invoke(tape.address, "seek", newPosition - position)
	end
end

-------------------------------- Pref/next tape button ------------------------------------------------

local previousTapeButton = window:addChild(newRoundMiniButton(2, 30, 0x2D2D2D, 0xFFB600, 0x0F0F0F, 0xCC9200, "<<"))
local nextTapeButton = window:addChild(newRoundMiniButton(7, 30, 0x2D2D2D, 0xFFB600, 0x0F0F0F, 0xCC9200, ">>"))

previousTapeButton.onTouch = function()
	incrementTape(false)
end

nextTapeButton.onTouch = function()
	incrementTape(true)
end

-------------------------------- Pref/next search button ------------------------------------------------

local previousSearchButton = window:addChild(newRoundMiniButton(2, 34, 0x2D2D2D, 0xFFB600, 0x0F0F0F, 0xCC9200, "<<"))
local nextSearchButton = window:addChild(newRoundMiniButton(7, 34, 0x2D2D2D, 0xFFB600, 0x0F0F0F, 0xCC9200, ">>"))

previousSearchButton.onTouch = function()
	
end

nextSearchButton.onTouch = function()
	
end

-------------------------------- Hot cue buttons ------------------------------------------------

local hotCueButtonA = window:addChild(newHotCueButton(3, 13, 0x66FF40, 0x336D00, "A"))
local hotCueButtonB = window:addChild(newHotCueButton(3, 16, 0xFFB600, 0x664900, "B"))
local hotCueButtonB = window:addChild(newHotCueButton(3, 19, 0xFF2440, 0x660000, "C"))
local hotCueSaveLoad = window:addChild(newHotCueButton(3, 23, 0x0F0F0F, 0x000000, "⠰⠆"))

hotCueSaveLoad.draw = function(button)
	local bg, fg = button.animationCurrentBackground, button.animationCurrentText

	-- Upper
	screen.drawText(button.x, button.y, bg, "⢀" .. string.rep("⣀", button.width - 2) .. "⡀")

	-- Left
	screen.drawText(button.x, button.y + 1, bg, "⢸")

	-- Middle
	screen.set(button.x + 1, button.y + 1, 0x2D2D2D, fg, " ")
	screen.set(button.x + 2, button.y + 1, 0x2D2D2D, fg, " ")
	screen.set(button.x + 3, button.y + 1, 0x2D2D2D, fg, "⠶")
	screen.set(button.x + 4, button.y + 1, 0x2D2D2D, fg, " ")
	screen.set(button.x + 5, button.y + 1, 0x2D2D2D, fg, " ")

	-- Right
	screen.drawText(button.x + button.width - 1, button.y + 1, bg, "⡇")

	-- Lower
	screen.drawText(button.x, button.y + button.height - 1, bg, "⠈" .. string.rep("⠉", button.width - 2) .. "⠁")
end


hotCueButtonA.onTouch = function()
	
end

-------------------------------- Loop buttons ------------------------------------------------

local function loopButtonDraw(button)
	local border, color1, color2, color3, color4

	if powerButton.pressed then
		if button.pressed then
			border, color1, color2, color3, color4 = 0x332400, 0x996D00, 0x996D00, 0x996D00, 0x996D00
		else
			border, color1, color2, color3, color4 = 0x332400, 0xFFDB80, 0xFFDB40, 0xFFB680, 0xFFB640
		end
	else
		border, color1, color2, color3, color4 = 0x0F0F0F, 0x332400, 0x332400, 0x332400, 0x332400
	end

	-- 1
	screen.drawText(button.x, button.y, border, "⢰")
	screen.set(button.x + 1, button.y, color1, border, "⠉")
	screen.set(button.x + 2, button.y, color2, border, "⠉")
	screen.set(button.x + 3, button.y, color3, border, "⠉")
	screen.drawText(button.x + 4, button.y, border, "⡆")

	-- 2
	screen.drawText(button.x, button.y + 1, border, "⠸")
	screen.set(button.x + 1, button.y + 1, color4, border, "⣀")
	screen.set(button.x + 2, button.y + 1, color4, border, "⣀")
	screen.set(button.x + 3, button.y + 1, color3, border, "⣀")
	screen.drawText(button.x + 4, button.y + 1, border, "⠇")
end

local function loopButtonEventHandler(workspace, button, e1, e2, e3, e4, e5)
	if e1 == "touch" then
		button.pressed = true
		workspace:draw()
		
		event.sleep(0.2)

		button.pressed = false
		workspace:draw()

		if button.onTouch then
			button.onTouch()
		end
	end
end

local function newLoopButton(x, y)
	local button = GUI.object(x, y, 5, 2)

	button.pressed = false
	button.draw = loopButtonDraw
	button.eventHandler = loopButtonEventHandler

	return button
end


local loopButtonIn = window:addChild(newLoopButton(13, 18))
local loopButtonOut = window:addChild(newLoopButton(19, 18))

local reloopButton = window:addChild(newRoundTinyButton(26, 18, 0x2D2D2D, 0xFFB640, 0x1E1E1E, 0x996D00, "⢠⡄"))

loopButtonIn.onTouch = function()
	
end

-------------------------------- Cue button ------------------------------------------------

local cueButton = window:addChild(newImageButton(2, window.height - 11, 9, 5, "Cue"))

cueButton.eventHandler = function(workspace, cueButton, e1)
	if e1 == "touch" then
		workspace:draw()
	end
end

-------------------------------- Play button ------------------------------------------------

local playButton = window:addChild(newImageButton(2, window.height - 5, 9, 5, "Play"))

playButton.blinking = true

playButton.eventHandler = function(workspace, playButton, e1)
	if e1 == "touch" and powerButton.pressed then
		playButton.blinking = not playButton.blinking

		component.invoke(tape.address, playButton.blinking and "stop" or "play")

		workspace:draw()
	end
end

-------------------------------- Right beat buttons ------------------------------------------------

local beatSyncButton = window:addChild(newRoundMiniButton(70, 24, 0xB4B4B4, 0x0F0F0F, 0x787878, 0x0F0F0F, "Sy"))
local beatSyncMasterButton = window:addChild(newRoundMiniButton(74, 24, 0xB4B4B4, 0x0F0F0F, 0x787878, 0x0F0F0F, "Ms"))

-------------------------------- Right tempo buttons ------------------------------------------------

local tempoButton = window:addChild(newRoundTinyButton(72, 28, 0x0F0F0F, 0x2D2D2D, 0x0, 0xFF2440, " "))

local masterTempoButton = window:addChild(newRoundTinyButton(72, 31, 0x0F0F0F, 0x2D2D2D, 0x0F0F0F, 0xFF0000, "⢠⡄"))
masterTempoButton.switchMode = true
masterTempoButton:press()

tempoButton.onTouch = function()
	
end


-------------------------------- Events ------------------------------------------------

local jogIncrementSpeedMin = 0.05
local jogIncrementSpeedMax = 1
local jogIncrementUptime = 0

local overrideWindowEventHandler = window.eventHandler

window.eventHandler = function(workspace, window, e1, ...)
	overrideWindowEventHandler(workspace, window, e1, ...)

	local shouldDraw = false
	local isPlaying = getIsPlaying()

	local uptime = computer.uptime()

	-- Cheching if play button state was changed
	if isPlaying == playButton.blinking then
		playButton.blinking = not playButton.blinking
		shouldDraw = true
	end

	if isPlaying then
		if uptime > jogIncrementUptime then
			-- Rotating jog
			currentJogIndex = currentJogIndex + 1

			if currentJogIndex > #jogImages then
				currentJogIndex = 1
			end

			jogIncrementUptime = uptime + (1 - speedSlider.value) * (jogIncrementSpeedMax - jogIncrementSpeedMin)
			shouldDraw = true
		end
	else
		jogIncrementUptime = uptime + (1 - speedSlider.value) * (jogIncrementSpeedMax - jogIncrementSpeedMin)
	end

	-- Blink
	if uptime > imageButtonBlinkUptime then
		imageButtonBlinkUptime = uptime + imageButtonBlinkInterval
		imageButtonBlink = not imageButtonBlink
		shouldDraw = true
	end

	if shouldDraw then
		workspace:draw()
	end
end


---------------------------------------------------------------------------------

updateTapes()

workspace:draw()
