--[[
-- Author: Larry Knaebel
-- disclaimer: This is my first lua script, use with low expectations :)
-- FlyWithLua required
-- credits: used display_clist.lua from Carsten Lynker to learn my first steps with FlyWithLua and copied some of his code -- thanks Carsten :)
-- Sets weather based on metar data nearest the aircraft every 10 minutes (currently only altimeter,winds,clouds,rain)
-- Loads raw weather from local metar file.  You can get this file free from ADDS.
-- A windows helper script is included that can download the data from ADDS and extract only the airports you need
-- Put the list of the airports you want to read into XPlane into a .airports file in the plugin folder
-- A provided script will call 'curl' to get the file and place it into a temp folder and then run a findstr on it 
-- to collect only the metars you need.
-- When the aircraft loads, you have to load the FlyWithLua plugins so that the weather will set to the closest airport found


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

local weatherFileRaw = ".weather.raw"
local weatherTable = {{}}
local linecount = 0
local windowPosTable = {}
local lineHeightPix = 13
local closestIndex = 0
local lastTriggered = 0
local updateConditionsSeconds = 600
local windowWidth = 1500
local LJK_debug = true

--local altimeterDR   = XPLMFindDataRef("sim/weather/barometer_sealevel_inhg")
--local altimeterDR
--dataref("altimeterDR","sim/weather/barometer_sealevel_inhg","writable")
-- sim/cockpit/misc/barometer_setting
-- sim/cockpit/misc/barometer_setting2
-- sim/weather/barometer_sealevel_inhg
-- sim/weather/wind_speed_kt -- DOCS SAY THIS IS The effective speed of the wind at the plane's location. WARNING: this dataref is in meters/second - the dataref NAME has a bug.
-- sim/weather/wind_speed_kt[0] -- low
-- sim/weather/wind_speed_kt[1] -- mid
-- sim/weather/wind_speed_kt[2] -- high
-- sim/weather/wind_direction_degt[0]
-- sim/weather/wind_direction_degt[1]
-- sim/weather/wind_direction_degt[2]
--nav_reference = XPLMFindNavAid(inNameFragment, inIDFragment, inLat, inLon, inFrequency, inType)
--nav_reference = XPLMFindNavAid(nil, nil, inLat, inLon, nil, inType)
--nav_nearest = XPLMFindNavAid(nil, nil, inLat, inLon, nil, 1)
-- sim/flightmodel/position/latitude
--sim/flightmodel/position/longitude
--DataRef("Wind_WDir", "sim/cockpit2/gauges/indicators/wind_heading_deg_mag", "readonly")
--DataRef("Wind_WSpd", "sim/cockpit2/gauges/indicators/wind_speed_kts", "readonly")
--DataRef("current_heading", "sim/flightmodel/position/psi", "readonly")
--sim/weather/visibility_reported_m

dataref("LJK_altimeterDR","sim/cockpit/misc/barometer_setting","writable")
dataref("LJK_altimeterDR2","sim/cockpit/misc/barometer_setting2","writable")
dataref("LJK_surfaceWindSpeed","sim/weather/wind_speed_kt[0]","writable")
dataref("LJK_surfaceWindDirection","sim/weather/wind_direction_degt[0]","writable")
dataref("LJK_visibility","sim/weather/visibility_reported_m","writable")
dataref("LJK_cloudType0","sim/weather/cloud_type[0]","writable")
dataref("LJK_cloudType1","sim/weather/cloud_type[1]","writable")
dataref("LJK_cloudType2","sim/weather/cloud_type[2]","writable")
dataref("LJK_cloudBase0","sim/weather/cloud_base_msl_m[0]","writable")
dataref("LJK_cloudBase1","sim/weather/cloud_base_msl_m[1]","writable")
dataref("LJK_cloudBase2","sim/weather/cloud_base_msl_m[2]","writable")
dataref("LJK_cloudCoverage0","sim/weather/cloud_coverage[0]","writable")
dataref("LJK_cloudCoverage1","sim/weather/cloud_coverage[1]","writable")
dataref("LJK_cloudCoverage2","sim/weather/cloud_coverage[2]","writable")
dataref("LJK_rainpercent","sim/weather/rain_percent","writable")

--sim/cockpit2/temperature/outside_air_temp_degc (field 5) - not writable


--22 SkyCover[0] CLR, OVC,OVX,CAVOK,SCT,FEW,BKN
--23 Cloud Base[0]

-- 1 foot = .3048 meters

-- 2100 feet = 640 meters

local function distanceNM(lat1,lon1,lat2,lon2)
	local dNM = math.sin(lat1 * math.pi / 180) * math.sin(lat2 * math.pi / 180) +
		math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
		math.cos(lon2 * math.pi / 180 - lon1 * math.pi / 180) 
	return math.acos(dNM) * 3443.8985 
end

--returns the weatherTable index of the closest METAR loaded
local function getClosestIndex(metarTable)
	local closest = 0
	local dist = 100000.11111
	local tdist = 0
	
	for i = 0,#metarTable do
		tdist = distanceNM(		
			metarTable[i].parsed[3],
			metarTable[i].parsed[4],
			LATITUDE,
			LONGITUDE)
		if  tdist < dist then
			dist = tdist
			closest = i
		end
	end
	return closest

end

--returns the proper digit for the given string code
local function getSkyCoverNum(skycoverabbrev)
--Clear = 0, High Cirrus = 1, Scattered = 2, Broken = 3, Overcast = 4, Stratus = 5 (740 and newer)

    result = 0
	--print("skycoverabbrev : " .. skycoverabbrev)
	if skycoverabbrev == "CLR" then
		result = 0
	elseif skycoverabbrev == "FEW" then
		result = 2
	elseif skycoverabbrev == "SCT" then
		result = 2
	elseif skycoverabbrev == "BKN" then
		result = 3
	elseif skycoverabbrev == "OVC" then
		result = 5
	end
	--print("sky cover result: "..result)
	return result
end

local function setSkyCoverDataRefs()
--22 SkyCover[0] CLR-0, OVC-4,OVX,CAVOK,SCT-2,FEW,BKN-3
--23 Cloud Base[0]
	local skynum = 0
	if weatherTable[closestIndex].parsed[22] then
		skynum = getSkyCoverNum(weatherTable[closestIndex].parsed[22])
		LJK_cloudType0 = skynum
		LJK_cloudCoverage0 = skynum
		if(tonumber(weatherTable[closestIndex].parsed[23]) ~= nil) then
			LJK_cloudBase0 = (tonumber(weatherTable[closestIndex].parsed[23]) * .3048)
		else
			LJK_cloudBase0 = 0
		end
		if LJK_debug then
			print("Value of cloudbase0: " .. weatherTable[closestIndex].parsed[23] .. ">"..LJK_cloudBase0.." meters")
			--print(">"..LJK_cloudBase0.." meters")
			print("Sky Coverage0: " .. weatherTable[closestIndex].parsed[22])
			print("skynum0="..skynum)
		end
		
	end
	if weatherTable[closestIndex].parsed[24] then
		skynum = getSkyCoverNum(weatherTable[closestIndex].parsed[24])
		LJK_cloudType1 = skynum
		LJK_cloudCoverage1 = skynum
		if(tonumber(weatherTable[closestIndex].parsed[25]) ~= nil) then
			LJK_cloudBase1 = (tonumber(weatherTable[closestIndex].parsed[25]) * .3048)
		else
			LJK_cloudBase1 = 0
		end
		if LJK_debug then		
			print("Value of cloudbase1: " .. weatherTable[closestIndex].parsed[25] ..">"..LJK_cloudBase1.." meters")
			--print(">"..LJK_cloudBase1.." meters")
			print("Sky Coverage1: " .. weatherTable[closestIndex].parsed[24])
			print("skynum1="..skynum)
		end
	end
	if weatherTable[closestIndex].parsed[26] then
		skynum = getSkyCoverNum(weatherTable[closestIndex].parsed[26])
		LJK_cloudType2 = skynum
		LJK_cloudCoverage2 = skynum
		if (tonumber(weatherTable[closestIndex].parsed[27]) ~= nil) then
			LJK_cloudBase2 =  (tonumber(weatherTable[closestIndex].parsed[27]) * .3048) 
		else
			LJK_cloudBase2 = 0
		end
		if LJK_debug then		
			print("Value of cloudbase2: " .. weatherTable[closestIndex].parsed[27] .. ">"..LJK_cloudBase2.." meters")
			--print(">"..LJK_cloudBase2.." meters")
			print("Sky Coverage2: " .. weatherTable[closestIndex].parsed[26])
			print("skynum2="..skynum)
		end
	end
end

local function setRain()
	rs = weatherTable[closestIndex].parsed[21]
	--print("Rain is " .. rs);
	rainpercent = 0
	if rs ~= "" then
		print("RAIN is " .. rs)
		if string.find(rs,"-RA") then
			rainpercent = 20	
		elseif string.find(rs,"+RA") then
			rainpercent = 100
		elseif string.find(rs,"RA") then
			rainpercent = 60 
		elseif string.find(rs,"DZ") then
			rainpercent = 5
		end
		LJK_rainpercent = rainpercent
		--print("Set rain percent to " .. rainpercent)
	end
end

local function setConditionsDataRefs()
	closestIndex = getClosestIndex(weatherTable)
	if LJK_debug then
		print("Closest index: " .. closestIndex .. " " .. weatherTable[closestIndex].parsed[1])
		print("Setting sim/cockpit/misc/barometer_setting to " .. weatherTable[closestIndex].parsed[11])
		print("Setting sim/weather/wind_speed_kt[0] to " .. weatherTable[closestIndex].parsed[8])
		print("Setting sim/weather/wind_direction_degt[0] to " .. weatherTable[closestIndex].parsed[7])
		print("Setting sim/weather/visibility_reported_m to " .. tonumber(weatherTable[closestIndex].parsed[10]) * 1609)
	end
	LJK_altimeterDR = weatherTable[closestIndex].parsed[11]
	LJK_altimeterDR2 = weatherTable[closestIndex].parsed[11]
	LJK_surfaceWindDirection = weatherTable[closestIndex].parsed[7]
	LJK_surfaceWindSpeed = weatherTable[closestIndex].parsed[8]
	if(tonumber(weatherTable[closestIndex].parsed[10]) ~= nil) then
		LJK_visibility = tonumber(weatherTable[closestIndex].parsed[10]) * 1609 -- visibility in meters
	else
		LJK_visibility = 999999.9
	end
	setRain()
	setSkyCoverDataRefs()
	lastTriggered = os.clock()
end


local function setWindowPosTable()
	local windowHeightPix = lineHeightPix + 5
	windowPosTable["lower.left.x"] = 0
	windowPosTable["lower.left.y"] = SCREEN_HIGHT - y_offset - windowHeightPix
	windowPosTable["upper.right.x"] = windowWidth
	windowPosTable["upper.right.y"] = SCREEN_HIGHT - y_offset 
	windowPosTable["height"] = windowPosTable["upper.right.y"] - windowPosTable["lower.left.y"] 
end

--https://stackoverflow.com/questions/1426954/split-string-in-lua
local function split(inputstr, sep) 
	sep=sep or '%s' 
	local t={} 
	for field,s in string.gmatch(inputstr, "([^"..sep.."]*)("..sep.."?)") do 
		table.insert(t,field) 
		if s=="" then return t 
		end 
	end 
end

local function load_weather( filename )
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
		weatherTable[linecount].firstpart = string.sub(line,1,first - 1)
		weatherTable[linecount].parsed = {}
		local restpart = string.sub(line,first + 1)
		local myresult = split(restpart,',')
		weatherTable[linecount].parsed = myresult
		linecount = linecount + 1
	end
	rawfile:close()
	logMsg(string.format('Processed file "%s containing %d entries"', filename,linecount+1))
	setWindowPosTable() 
	-- version 1 displayed multiple lines and therefore setWindowPosTable must be called after loading the file to see how many lines there are; 
	-- version 2 no longer uses more than one line but still needs to be initialized
	setConditionsDataRefs() 
	--[[
	TODO:  Why does loading the aircraft/situation not cause the weather to be displayed.  
	       Currently the script must be re-loaded for the weather (rain, clouds) to display on the screen
	--]]
end



local function myTest(a)
	print("MYTEST FUNCTION:" .. a)
end


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



function display_metar()
		XPLMSetGraphicsState(0,0,0,1,1,0,0)
		glColor4f(0,0,0,transparent_percent)
		--glRectf(windowPosTable["lower.left.x"], windowPosTable["lower.left.y"], windowPosTable["upper.right.x"], windowPosTable["upper.right.y"])
		glColor4f(1,1,1,1)
		draw_string_Helvetica_12(windowPosTable["lower.left.x"], windowPosTable["lower.left.y"] + windowPosTable["height"] - (lineHeightPix ) , weatherTable[closestIndex].firstpart )
		glEnd()
	if os.clock() - lastTriggered > updateConditionsSeconds then 
		lastTriggered = os.clock()
		print("Timer Fired: " .. os.clock())
		setConditionsDataRefs()
	end
end





-- these are executed one time per FlyWithLua specs
load_weather(SCRIPT_DIRECTORY .. weatherFileRaw)
--setConditionsDataRefs() 
--command_once("load_weather(SCRIPT_DIRECTORY .. weatherFileRaw)")
--command_once("setConditionsDataRefs()")
--display_metar() -- cannot call this outside a callback

-- below is executed on every draw
do_every_draw("display_metar()")

--[[

raw_text,station_id,observation_time,latitude,longitude,temp_c,dewpoint_c,wind_dir_degrees,wind_speed_kt,wind_gust_kt,visibility_statute_mi,altim_in_hg,sea_level_pressure_mb,corrected,auto,auto_station,maintenance_indicator_on,no_signal,lightning_sensor_off,freezing_rain_sensor_off,present_weather_sensor_off,wx_string,sky_cover,cloud_base_ft_agl,sky_cover,cloud_base_ft_agl,sky_cover,cloud_base_ft_agl,sky_cover,cloud_base_ft_agl,flight_category,three_hr_pressure_tendency_mb,maxT_c,minT_c,maxT24hr_c,minT24hr_c,precip_in,pcp3hr_in,pcp6hr_in,pcp24hr_in,snow_in,vert_vis_ft,metar_type,elevation_m
5 temp_c
7 wind_dir_degrees
8 wind_speed_kt
9 wind_gust_kt
10 visibiliy_statute_mi
11 altim_in_hg
31 BR, -RA,-DZ BR
21 Weather and/or obstruction to visibility (RA BR FU)
22 SkyCover[0] CLR, OVC,OVX,CAVOK,SCT,FEW,BKN
23 Cloud Base[0]
24 Sky Cover[1]
25 CloudBase[1]
26 SkyCover[2]
27 CloudBase[2]
28 SkyCover
29 CloudBase
30 FlightCategory VFR,MVFR,IFR
42 metar_type

--]]