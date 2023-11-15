::@ECHO OFF

mkdir export\Resources\Client
mkdir export\Resources\Server\RaceMP

CD Resources\Client

7z.exe a -tzip ..\..\export\Resources\Client\RaceMP.zip lua scripts LICENSE -aoa -r
7z.exe a -tzip ..\..\export\Resources\Client\RaceMP_tracks.zip art levels LICENSE -aoa -r

CD ..\..

Copy Resources\Server\RaceMP\RaceMP.lua export\Resources\Server\RaceMP\RaceMP.lua

CD export
7z.exe a -tzip ..\RaceMP.zip Resources -aoa -r