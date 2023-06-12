# Poormansweather FlyWithLua plugin for X-Plane 10 

A FlyWithLua plugin providing some (real-world) weather updates while flying the XPlane 10 simulator.

These files are located in the X-Plane 10\Resources\plugins\FlyWithLua\Scripts folder.

Before starting the Flight simulator, use the .refreshweather.cmd script to
obtain the real world weather for the airports you will be flying near.

The .airportlist file must contain the airports you desire to have live
weather information.

The script will create a .weather.raw file used to extract the weather used to update the simulator.

There are some other weather files provided here that you could copy from to create your own
.weather.raw file before your flight begins.

After starting the simulator at your starting airport, you must load the
FlyWithLua software using the simulator menu option.

The current station weather will be loaded and as the airplane flies,
the weather will be updated every 10 minutes based on the closest station.
