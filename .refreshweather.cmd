@echo off
rem This script downloads the raw metar file from ADDS and then will extract only those airports
rem you specify for xplane to autoconfigure.  You provide a list of the airports you want in the
rem MYAIRPOSTLIST file
rem Currently only altimeter, surface wind direction, surface wind speed is auto configured
rem Get raw METAR data from ADDS - link below
rem https://www.aviationweather.gov/adds/dataserver_current/current/metars.cache.csv
rem Set the variables for your environment
rem The MYAIRPORTLIST is a list at or around the airports you normally.
rem The idea is to limit the amount of memory used by unneccessary airports. 
rem Use curl if you have it, otherwise you can always manually download the metars raw data 
set FULLMETARFILEPATH=C:\Users\larry\Dropbox\tmp\metars.cache.csv
set MYAIRPORTSLIST=.airportlist
curl -o %FULLMETARFILEPATH% https://www.aviationweather.gov/adds/dataserver_current/current/metars.cache.csv 
findstr /B /G:%MYAIRPORTSLIST% %FULLMETARFILEPATH% > .weather.raw
echo Done