# Traitor!

![Logo](./ExternalAssets/Images/Promotional/Game%20Thumbnail.png)

## A Note

Traitor has been a labour of love for me since I started on it in 2022. Since then, I have grown a lot both as a person and as a developer. As work on Traitor has largely wrapped up, and prospect of success of the platform has dwindled, I decided to open source it for the good of the small community that has formed around this and similar games.

Unlike [Imperium](https://github.com/Skekdog/Imperium), I think that Traitor actually has a pretty good codebase. Of course, over the years it has gained some crust, but I largely believe it can be a pretty good model for others to follow.

To the people who have been around for Traitor's development - thank you.

## About

Spy HQ has been infiltrated by traitor spies - will you find them, or will they find you?

## Links

- [Main Game](https://www.roblox.com/games/2848381272/)
- [Labs](https://www.roblox.com/games/118757439615813/)

Labs is a separate environment used to create and test custom assets. Data is not saved, and private servers must be used.

Play here:

## Developing

### Setup

1. Start by cloning the repo:

```bash
git clone https://github.com/Skekdog/Traitor.git Traitor
```

2. Initialise submodules:

```bash
git submodule update --init --recursive
```

3. Install tools required, for example with Rokit:

```bash
rokit install
```

You can find the required tools and their versions in [rokit.toml](./rokit.toml).

4. Run Dev Script:

```bash
lune run Lune/Dev
```

### Required Adjustments

A `.env` file should be created:

```toml
APIKEY="Key to upload project builds to Roblox"
UPLOADER_KEY="Admin key for Traitor Uploader to upload default SDK assets"
```

The following also need to be amended:

- [Place IDs](./Source/Shared/Places/PlaceIDs.luau)
- [Badge IDs](./Source/Shared/Monetisation/BadgeIDs.luau)
- [Gamepass IDs](./Source/Shared/Monetisation/GamepassIDs.luau)

### Project Structure

Client code and shared client / server code lives in [Source/Shared](./Source/Shared).

Server code is found in [Source/Server](./Source/Server).

Public API, to be used for maps, gamemodes, and other custom assets, is found in [Source/API](./Source/API).

The game is broadly split into two parts: the core engine responsible for gamemode handling, and the client and server code to interface with it. The core engine is a separate submodule, [RoundRule](https://github.com/Skekdog/RoundRule).

### Additional Repositories

Traitor has ended up as a project larger than just a game, and as such, there are many side-repositories related to it:

- [Traitor SDK](https://github.com/Skekdog/Traitor-SDK) (Studio plugin to aid with custom map and gamemode development)
- [Traitor Docs](https://github.com/Skekdog/Traitor-Docs) (Documentation for the public API)
- [Traitor Uploader](https://github.com/Skekdog/Traitor-Uploader) (System to upload custom assets built with the SDK plugin)

### Tips

- Testing can be substantially sped up using [console commands](https://skekdog.github.io/Traitor-Docs/guides/commands/).

## Credits

3rd party licenses can be found in [here](./Assets/Server/Licenses/).

Map credits can be found in [CREDITS.md](./CREDITS.md).