# RaceMP
> ## A racing mod for [BeamMP](https://beammp.com/)

Uses BeamNGTriggers as checkpoints and racing bounderies

Includes tracks from West Coast, USA, Automation Test Track, Hirochi Raceway, and way more. 

# Installation
Download latest release `RaceMP.zip` in [Releases](https://github.com/AbhiMayadam/RaceMP/releases)

Unzip `RaceMP.zip` into the root of your BeamMP server

# Usage
### Interaction uses chat commands:
* `/list` to list tracks

* `/set` to set race paramaters
    * `laps=n` where `n` is the number of laps
    * `track=trackName` where `trackName` is the name of a track from `/list`
    * `raceName=name` where `name` is the name of the race (shown on the leaderboard)
* `/start` to reset laps and start a countdown

# Making a track in BeamNG Drive
### Prerequisites
Clone this repository first with `git clone https://github.com/AbhiMayadam/RaceMP.git`. 
Install 7-Zip and add its install folder to Path. [Here is a guide on Stack Overflow.](https://stackoverflow.com/questions/44272416/how-to-add-a-folder-to-path-environment-variable-in-windows-10-with-screensho)
  1. Opening World Editor
  2. Make a new group in Scene Tree.
  3. Opening up Asset Browser and importing BeamMP triggers.prefab.json (at camera or at origin is fine).
  4. Move the imported prefab to the new group (mainly for organization's sake)
  5. Unpack the prefab and move the out of bounds, startstop, and lapsplit items out of the prefab to the folder you just made. (Again, for organization's sake so you don't overwrite your template.)
  6. Delete the old prefab.
  7. Drag startStop to your start/finish line, or if you are doing a sprint race, put the start trigger at the start line, and the stop trigger at the finish line. Delete the one you aren't using. (THIS IS MANDATORY)
  8. Put outOfBounds markers across areas that you don't want people to run. (You can duplicate these, and these are not necessary)
  9. Put lapSplit markers wherever you want to record splits/sectors. (You can duplicate these if you need more, just try to put them in order (like lapSplit1 goes before lapSplit 2 etc)
  10. Make the triggers as wide and as tall as necessary. I would recommend making the trigger wider than you'd expect to reduce the chances of the racers not being picked up by the triggers. 
  11. You can add other assets to the track like tire bundles, flags to denote splits etc. if you want it to be loaded alongside the race markers. I would recommend putting it in the group with all the markers.
  12. Highlight all the markers and every other race asset you used and pack into prefab. Name it something that is memorable and short. Save it to a folder (this starts out in your BeamNG AppData folder), and I recommend making a folder in this main level, and saving tracks in that. Call it "prefab_tracks" or something.
  13. Once the prefab is saved, do not save the level, and close it, we don't want any theoretical conflicts.
  14. Go to your BeamMP AppData folder `%appdata%\..\Local\BeamNG.drive` and go to the levels folder. Copy your modified map folder (ex. the ks_spa folder) to the `RaceMP\Resources\Client\levels` folder. (This folder is located in the repository you cloned.)
  15. Enter your modified map folder, make a "multiplayer" folder and copy your track prefab.json file into this. Your final folder should have a "main" folder, a "multiplayer" folder, and a main.decals.json folder. The [ks_spa folder](https://github.com/AbhiMayadam/RaceMP/tree/main/Resources/Client/levels/ks_spa) has the correct layout if you need an example.
  16. Run the compress.bat script and it will make a .zip that contains all of the server side code, the client side code, and the maps. Put this in your server following the installation instructions.

  Thank You to Funky7Monkey for making the mod initially. If you want to go to their original Gitea repository, you can do so here. https://git.funky7monkey.moe/funky7monkey/RaceMP. Their Gitea is self hosted and occasionally goes down so keep that in mind. My initial commit to this Github repository is the same source code so you can download that if you are so inclined.

  Thank you to Lakota Lewulf for giving me their layouts for a bunch of tracks so I don't have to do as much work in making tracks. I will slowly add tracks to this repository as I make more for different events. If you made some already and want them to be added to this repository, please feel free to make a PR. Also if you have any issues, please make an issue and I will try my best to get to it. This is not my codebase and my lua knowledge is basically nonexistent, but I will try.
