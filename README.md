# PoorMansWeather 
# FlyWithLua plugin for X-Plane 10 

A FlyWithLua plugin providing some (real-world) weather updates while flying the XPlane 10 simulator.

Newer X-Plane versions have real-world weather capabilities built-in.

The files in this repository must be located in the X-Plane 10\Resources\plugins\FlyWithLua\Scripts folder.

Before starting the Flight simulator, 
use the .refreshweather.cmd script to 
obtain the real world weather for the 
airports you will be flying near. 
The .airportlist file must contain 
the airports for which you desire to have live
weather information. The script will 
create a .weather.raw file used to 
extract the simulator's weather 
during the flight.  

There are some other weather files provided here that you could copy from to create your own
.weather.raw file before your flight begins.

After starting the simulator at your starting airport, you must load the
FlyWithLua software plugin using the simulator's plugin menu option.

The current station weather will be immediately loaded and as the airplane flies,
the weather will be updated every 10 minutes based on the closest station to the
aircrafts location.

The plugin code is found in the PoorMansWeather.lua file. You may alter the code as you like
for your needs.