# Realmshade

The game is work in progress. No stable release version is available yet.  
The repository is made public to test the compatability of Godot game hosted on Github Pages with multiplayer.

## How to play
You can play the latest version of the game at [https://shadecoredev.github.io/Realmshade/game](https://shadecoredev.github.io/Realmshade/game).  
With the help of [Github Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages) the latest version of the game can be played directly from source code.

## Overview
Realmshade is an open-source game created as an experiment of a fully moddable multiplayer game.  
Main gameplay loop is an inventory management auto battler inspired by games like [Backpack Hero](https://store.steampowered.com/app/1970580/Backpack_Hero/), [Backpack Battles](https://store.steampowered.com/app/2427700/Backpack_Battles/) and [The Bazaar](https://store.steampowered.com/app/1617400/The_Bazaar/).

## Modding
To mod the Realmshade you can just clone the repository and edit the files.
You also need to have [Godot engine downloaded](https://godotengine.org/) to run the game.  

Cool thing about this game is that if you mod the game ~~and don't crash it in the process~~,   you can still play the PvP matches with your own balance changes, custom items, events and any other major feature changes.  

The idea behind it is that you can make some additions and test them directly by playing the game, then make a [pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests) to propose the changes into the original game.

All gameplay entities like items and events are located in [`Realmshade/game/data/`](https://github.com/shadecoredev/Realmshade/tree/main/game/data) folder.  
Each game entity is stored as a JSON file.  
New items can be added by creating new entries in this `data/` folder.  

I will add docs on creating new content once the stable realease version will be completed.

## Cheating
Realmshade is running without any anticheats or authorization, so why wouldn't someone just edit the code to set a weapon's damage to 1 billion, duplicate items and cheat a high score?  

There are several design decisions made to prevent cheating and griefing possible.  

Every event, PvE encounter, PvP fight, shop item and reward is determined by a RNG with a starting seed value, a 64-bit integer number.  
Each item holds metadata of the event where it was acquired:
- When you craft items together, the resulting item holds metadata of the ingredients;  
- When you sell an item to gain gold, the resulting coin holds metadata of the sold item;  
- When you buy an item, it recieves the metadata of the coin you used to pay for it;  
- Etc.
  
This way each item holds a history of how it was acquired and can be compared to a seed value to determine if it's legitimate.

Main cheating detection happens at the server.  
When you win, you send your username, seed value and metadata of each item you own in your inventory.  
The server processes the data to determine if your items correspond to your seed then runs your fight to deterine if you actually won it.  
Only successfully validated players added to the leaderboard and PvP player pool.  

That means that you can patch the game, test, add or remove new content however you want without affecting other players.  

Regarding the authorization, the worst a player typing your username can do is rise your score on the leaderboard.  
The leaderboard only holds validated players and highest victory positions, so there's no downside of somebody playing under your username.

## Copyright
Copyright notice is located in `LICENSE.txt`.  

All gameplay sprites are licensed under CC BY-NC 4.0.  
Source code is avaliable under MIT license.
