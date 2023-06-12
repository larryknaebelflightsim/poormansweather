--[[
-- Author: Larry Knaebel
-- disclaimer: This is my first lua script, use with low expectations :)
-- FlyWithLua required
-- credits: used display_clist.lua from Carsten Lynker to learn my first steps with FlyWithLua and copied some of his code -- thanks Carsten :)
-- Loads raw weather from local file


KMTC 012356Z 00000KT 10SM FEW160 SCT200 15/03 A3001 RMK AO2A SLP169 T01490031 10167 20148 52008 $,KMTC,2020-05-01T23:56:00Z,42.62,-82.82,14.9,3.1,0,0,,10.0,30.008858,1016.9,,,TRUE,TRUE,,,,,,FEW,16000,SCT,20000,,,,,VFR,0.8,16.7,14.8,,,,,,,,,METAR,177.0
KDTW 012353Z 16004KT 10SM BKN220 16/03 A3003 RMK AO2 SLP169 T01610033 10189 20161 53013,KDTW,2020-05-01T23:53:00Z,42.23,-83.33,16.1,3.3,160,4,,10.0,30.029528,1016.9,,,TRUE,,,,,,,BKN,22000,,,,,,,VFR,1.3,18.9,16.1,,,,,,,,,METAR,195.0
KPHN 020035Z AUTO 00000KT 10SM CLR 11/00 A3003 RMK AO2,KPHN,2020-05-02T00:35:00Z,42.92,-82.52,11.0,0.0,0,0,,10.0,30.029528,,,TRUE,TRUE,,,,,,,CLR,,,,,,,,VFR,,,,,,,,,,,,METAR,198.0
KFNT 012353Z 27004KT 10SM CLR 16/02 A3002 RMK AO2 SLP167 T01560017 10194 20156 51007,KFNT,2020-05-01T23:53:00Z,42.97,-83.75,15.6,1.7,270,4,,10.0,30.02067,1016.7,,,TRUE,,,,,,,CLR,,,,,,,,VFR,0.7,19.4,15.6,,,,,,,,,METAR,233.0
--]]


require("graphics")

-------8<---directly from Carsten's script---------------------------------------------------
-- You can edit these 5 parameters to customize the output of this script.
local rowhight = 21                -- the line spacing in screen pixel
local framewidth = 5               -- the space between text and frame in screen pixel
local y_offset = 80                -- the distance of the window from the upper screen limit
local show_on_right_side = false   -- set this to true to display the pages on the right side
local transparent_percent = 0.65   -- the darkness of the windows background
---------------------------------------------------------------------->8---------------------

local weatherFileRaw = "weather.raw"
local weatherTable = {{}}
local linecount = 0
local windowPosTable = {}
local lineHeightPix = 13

--local altimeterDR   = XPLMFindDataRef("sim/weather/barometer_sealevel_inhg")
--local altimeterDR
dataref("altimeterDR","sim/cockpit/misc/barometer_setting","writable")
dataref("altimeterDR2","sim/cockpit/misc/barometer_setting2","writable")
--dataref("altimeterDR","sim/weather/barometer_sealevel_inhg","writable")

-- sim/cockpit/misc/barometer_setting
-- sim/cockpit/misc/barometer_setting2
-- sim/weather/barometer_sealevel_inhg
dataref("surfaceWindSpeed","sim/weather/wind_speed_kt[0]","writable")
dataref("surfaceWindDirection","sim/weather/wind_direction_degt[0]","writable")
-- sim/weather/wind_speed_kt -- DOCS SAY THIS IS The effective speed of the wind at the plane's location. WARNING: this dataref is in meters/second - the dataref NAME has a bug.
-- sim/weather/wind_speed_kt[0] -- low
-- sim/weather/wind_speed_kt[1] -- mid
-- sim/weather/wind_speed_kt[2] -- high
-- sim/weather/wind_direction_degt[0]
-- sim/weather/wind_direction_degt[1]
-- sim/weather/wind_direction_degt[2]
--nav_reference = XPLMFindNavAid(inNameFragment, inIDFragment, inLat, inLon, inFrequency, inType)
dataref("myLat","sim/flightmodel/position/latitude","readonly")
dataref("myLon","sim/flightmodel/position/longitude","readonly")
--nav_reference = XPLMFindNavAid(nil, nil, inLat, inLon, nil, inType)
--nav_nearest = XPLMFindNavAid(nil, nil, inLat, inLon, nil, 1)
-- sim/flightmodel/position/latitude
--sim/flightmodel/position/longitude
--DataRef("Wind_WDir", "sim/cockpit2/gauges/indicators/wind_heading_deg_mag", "readonly")
--DataRef("Wind_WSpd", "sim/cockpit2/gauges/indicators/wind_speed_kts", "readonly")
--DataRef("current_heading", "sim/flightmodel/position/psi", "readonly")





function load_weather( filename )
	logMsg(string.format('Trying to load weather file "%s"', filename))
	local rawfile = io.open( filename )
	local firstpart = ""
	local first = "" 
	local last = ""
	local myval = ""
	local linecount = 0
	for line in rawfile:lines() do
		weatherTable[linecount] = {}
		weatherTable[linecount].unparsed = line;
		first = string.find(line,",",1,true)
		--print("Mystring=".. string.sub(line,1,first - 1))
		weatherTable[linecount].firstpart = string.sub(line,1,first - 1)
		weatherTable[linecount].parsed = {}
		local restpart = string.sub(line,first + 1)
		--print("REST: " .. restpart)
		local itemcount = 0
		-- https://stackoverflow.com/questions/19262761/lua-need-to-split-at-comma
		--for word in restpart:gmatch('[^,%s]+') do
		local myresult = split(restpart,',')
		--print("MYRESULT OF SPLIT: " .. #myresult)
		--print(table.concat(myresults))
		weatherTable[linecount].parsed = myresult
		--[[
		for word in restpart:gmatch('[^,%s%,]+,') do
			--print("ITEM: " .. word)
			weatherTable[linecount].parsed[itemcount] = word
			itemcount = itemcount + 1
		end
		--]]
		--table.insert(t,w)
		--weatherTable[linecount].parsed = {}
		--weatherTable[linecount].parsed = t
		--table.insert(t,loadWeatherTable)
		--weatherTable["fields"] = t
		--print("BOTTOM")
		----print(weatherTable[linecount].unparsed)
		--print("Fields Table = ",table.concat(weatherTable[linecount],","))
		--print("From WeatherTable = ",table.concat(weatherTable))
		--print("WeatherTable=" .. table.concat(weatherTable[linecount],";"))
		--print("First item = " .. weatherTable[linecount]["fields"][0])
		--[[
		for i = 1,#weatherTable[linecount].parsed do
			print("TABLE ITEM: " .. i .. " " .. weatherTable[linecount].parsed[i])
			if weatherTable[linecount].parsed[i] == nil then
				print("ITEM IS NIL")
			end
		end
		--]]
		--print("Size of field table: " .. table.getn(weatherTable[linecount].parsed))
		linecount = linecount + 1
	end
	rawfile:close()
	logMsg(string.format('Processed file "%s"', filename))
	setWindowPosTable() -- must be called after loading the file to see how many lines there are
	--print("UNPARSED: " .. weatherTable[2].unparsed)
	--print("FIRSTPART: " .. weatherTable[2].firstpart)
	--print("FIELD TABLE: " .. table.concat(weatherTable[1].parsed),"|")
	--for key, value in next, weatherTable[1].parsed do
	--	print(key, value)
	--end
	--[[
	local rowMax = 4
	local fieldMax = 43
	for rowNum = 0,rowMax - 1  do
		--for fieldNum = 0,fieldMax do
			--test_showparsedfields(rowNum,fieldNum)
			test_showparsedfields(rowNum,1,"ICAO") -- ICAO
			--test_showparsedfields(rowNum,2,"TIME") -- TIME
			test_showparsedfields(rowNum,7,"WINDDIR") -- WIND DIR
			test_showparsedfields(rowNum,8,"WINDSPEED") -- WIND SPEED
			test_showparsedfields(rowNum,11,"ALTIMETER") -- WIND SPEED
			test_showparsedfields(rowNum,10,"VIS") -- VISIBILITY
			test_showparsedfields(rowNum,30,"FLIGHT CATEGORY") -- SKY CONDITION
		--end
	end
	--]]
	--test_showparsedfields(0,1)
	--test_showparsedfields(0,2)
	--test_showparsedfields(0,7)
	--print(table.concat(weatherTable[1].parsed,","))
	--print(weatherTable[1].parsed[30])
	myPositionTable = {}
	myPositionTable = getMyPos()
	print("My Position: " .. myPositionTable.lat .. myPositionTable.lon)
	closestIndex = getClosestIndex(weatherTable,myPositionTable)
	print("Closest index: " .. closestIndex)
	--test_showparsedfields(0,3,"LAT")
	--test_showparsedfields(0,4,"LON")
	print("Setting sim/cockpit/misc/barometer_setting to " .. weatherTable[closestIndex].parsed[11])
	print("Setting sim/weather/wind_speed_kt[0] to " .. weatherTable[closestIndex].parsed[8])
	print("Setting sim/weather/wind_direction_degt[0] to " .. weatherTable[closestIndex].parsed[7])
	altimeterDR = weatherTable[closestIndex].parsed[11] -- set altimeter in xplane
	altimeterDR2 = weatherTable[closestIndex].parsed[11] -- set altimeter2 in xplane
	surfaceWindDirection = weatherTable[closestIndex].parsed[7] -- set surface wind in xplane
	surfaceWindSpeed = weatherTable[closestIndex].parsed[8] -- set wind speed in xplane
	--print("NAV Nearest:" .. nav_nearest[0])
	

end
--[[
Fields
raw_text
----------------
0station_id
1observation_time
2latitude
3longitude
4temp_c
5dewpoint_c
6wind_dir_degrees
7wind_speed_kt
8wind_gust_kt
9visibility_statute_mi
10altim_in_hg
11sea_level_pressure_mb
12quality_control_flags
13wx_string
14sky_condition
15flight_category
16three_hr_pressure_tendency_mb
17maxT_c
18minT_c
19maxT24hr_c
20minT24hr_c
21precip_in
22pcp3hr_in
23pcp6hr_in
24pcp24hr_in
25snow_in
26vert_vis_ft
27metar_type
28elevation_m
--]]

--[[
local function setAltimeter()
	local
end
--]]


function test_showparsedfields(a,b,c)
    local rowcount = a
	local fieldnum = b
	local desc = c
	--print(rowcount,fieldnum,desc)
	if weatherTable[rowcount].parsed[fieldnum] then
		print(desc .. "Field=[".. rowcount .. "][" .. fieldnum .. "] |" .. weatherTable[rowcount].parsed[fieldnum] .. "|") 
	else
		print(desc .. "Field=nil")
	end
end

function add_fields()
		for w in string.gmatch(line, "%a+") do
			print(w)
			--weatherTable[linecount][itemcount] = w
			--print("Itemcount=" .. itemcount)
			--weatherTable[linecount][itemcount] = w
			t[itemcount] = w
			--print("table t= ",table.concat(t,","))
			itemcount = itemcount + 1			
		end
		table.insert(t,loadWeatherTable)
end

--directly from Carsten's script (partly)
-- move the page to the right (local helper function)
local function x_offset()
--	if show_on_right_side then
--		return SCREEN_WIDTH - checklist[page_to_show].width
--	else
		return 0
--	end
end

--directly from Carsten's script
local function x_title_offset()
--	if show_on_right_side then
--		return SCREEN_WIDTH - framewidth*2 - max_title_width
--	else
		return 0
--	end
end

function setWindowPosTable()
    --local lineHeightPix = 13
	--local lineHeight = 5  
	--print("linecount = " .. linecount)
	local windowHeightPix = lineHeightPix * linecount
	windowPosTable["lower.left.x"] = 0
	windowPosTable["lower.left.y"] = SCREEN_HIGHT - y_offset - windowHeightPix
	windowPosTable["upper.right.x"] = 1500
	windowPosTable["upper.right.y"] = SCREEN_HIGHT - y_offset 
	windowPosTable["height"] = windowPosTable["upper.right.y"] - windowPosTable["lower.left.y"] 
	--print("SCREEN_HIGHT=" .. SCREEN_HIGHT)
	--print("Window Height = " .. windowHeightPix)
	--print("windowPosSTable[lower.left.x]=" .. windowPosTable["lower.left.x"])
	--print("windowPosSTable[lower.left.y]=" .. windowPosTable["lower.left.y"])
	--print("windowPosSTable[upper.right.x]=" .. windowPosTable["upper.right.x"])
	--print("windowPosSTable[upper.right.y]=" .. windowPosTable["upper.right.y"])
	--print("windowPosSTable[height]=" .. windowPosTable["height"])
	
end

function display_metar()	
--	logMsg(loadedWeather[0])
	--print(loadedWeather[0])

	XPLMSetGraphicsState(0,0,0,1,1,0,0)
	glColor4f(0,0,0,transparent_percent)
	--glRectf(0, SCREEN_HIGHT - 100 - (10 * 12) , 1500, SCREEN_HIGHT - 70 )
	--glRectf(windowPosTable["lower.left.x"], windowPosTable["lower.left.y"], windowPosTable["upper.right.x"], windowPosTable["upper.right.y"])
	glColor4f(1,1,1,1)

    local numLine = 0;
	while(weatherTable[numLine])
		do
			--draw_string_Helvetica_12(windowPos["lower.left.x"], SCREEN_HIGHT - (numLine*12) - 80, loadedWeather[numLine])
			--draw_string_Helvetica_12(windowPosTable["lower.left.x"], windowPosTable["lower.left.y"] - (lineHeightPix * numLine), weatherTable[numLine])
			draw_string_Helvetica_12(windowPosTable["lower.left.x"], windowPosTable["lower.left.y"] + windowPosTable["height"] - (lineHeightPix * numLine) , weatherTable[numLine].firstpart)
			numLine = numLine + 1
		end
	
--]]
--glEnd()	
end

function getClosest()

end

function getMyPos()
	local myPos = {}
	myPos.lat = myLat
	myPos.lon = myLon
	return myPos
end

function distanceNM(lat1,lon1,lat2,lon2)
	local dNM = math.sin(lat1 * math.pi / 180) * math.sin(lat2 * math.pi / 180) +
		math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
		math.cos(lon2 * math.pi / 180 - lon1 * math.pi / 180) 
	return math.acos(dNM) * 3443.8985 
end

function getClosestIndex(metarTable,myPosTable)
	local closest = 0
	local dist = 100000.11111
	local tdist = 0
	
	--weatherTable[rowcount].parsed[fieldnum]
	print(metarTable[0].parsed[3])
	print(metarTable[0].parsed[4])
	for i = 0,#metarTable do
		tdist = distanceNM(		
			metarTable[i].parsed[3],
			metarTable[i].parsed[4],
			myPosTable.lat,
			myPosTable.lon )
		--print(tdist)
		if  tdist < dist then
			dist = tdist
			closest = i
			--print("dist,closest " .. dist .. closest)
		end
		--print(metarTable[i].icao .. " " .. tdist)
	end
	
	return closest

end

--https://stackoverflow.com/questions/1426954/split-string-in-lua
function split(inputstr, sep) sep=sep or '%s' local t={} for field,s in string.gmatch(inputstr, "([^"..sep.."]*)("..sep.."?)") do table.insert(t,field) if s=="" then return t end end end

-- these are executed one time per FlyWithLua specs
load_weather(SCRIPT_DIRECTORY .. weatherFileRaw)

do_every_draw("display_metar()")
