# Snipe Queue System

Made by Snipe and Cadburry (https://github.com/cadburry6969)

# Features:
- Priority Queue based on discord roles
- Stackable priority based on roles. If you have two roles one with 10 points and other with 20 points, you will have 30 priority points.
- Optimized
- Easy to use

# Installation

- Download the script. Make sure its named `snipe-queue`
- Ensure the script in your server.cfg `ensure snipe-queue`
- Configure the script. Check the `config.lua` and change it to your liking.
- Add your discord bot token and server id in `config_discord.lua`
- Add your discord role ids along with the points system in `config_discord.lua`
- Edit the button links in `presentCard.json` file

# Developer Options

- If you want to get the number of people in queue in any of your other script you can use the following exports:
```lua
exports['snipe-queue']:getQueueCount()
```

# FAQ's

Q: How do I know if queue is broken?

A: The animals on the queue ui will not move if the queue is broken.