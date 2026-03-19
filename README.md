# The Other Side of the Grind

A parody survivalcraft game built with [Love2D](https://love2d.org/). This is a joke game, but it does actually work.

Harvest Blockchain Ore Nodes, chop down Organic Free-Range Trees, and collect Cosmetic Flowers (DLC) in this Parody Survivalcraft Experience from the visionary team that brought you nothing.

## Download & Play

Pre-built binaries are available on the [Releases](https://github.com/cwage/game/releases) page:

- **Windows** — Download `game-win64.zip`, extract, and run `game.exe`
- **Linux** — Download `game-linux-x86_64.AppImage`, `chmod +x`, and run it
- **macOS** — Download `game-macos.zip`, extract, and run the `.app` bundle
- **Love2D** — Download `game.love` and run with `love game.love`

Or run from source with Love2D installed:

```
cd src && love .
```

## Building

Builds are fully dockerized and produce binaries for Windows, macOS, and Linux:

```
docker compose run --rm build
```

Output goes to `build/`.

## License

MIT
