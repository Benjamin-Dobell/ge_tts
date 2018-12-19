# Glass Echidna Tabletop Simulator Libraries

Documentation is a work in progress, pull/merge requests welcome.

## License

Everything in this repository is permissively licensed under the MIT license, please refer to the `LICENSE` file.

### EmmyLua and Jetbrains IntelliJ IDEA

For development of your TTS mod we highly recommend using Jetbrains IntelliJ IDEA with the [EmmyLua](https://github.com/EmmyLua/IntelliJ-EmmyLua) (_not_ the plugin simply called 'Lua') to write your code, instead of (or rather in conjunction with) Atom and the Atom TTS plugin.

[IntelliJ Community Edition](https://www.jetbrains.com/idea/download/) and EmmyLua are both free, and offer significantly more advanced Lua editing capabilities than Atom.

Most importantly, we've included EmmyLua type definitions for our APIs. This means that when you use our types, function and variable names will auto-complete.

_However_, at present there is not yet a Tabletop Simulator plugin available for Jetbrains IntelliJ IDEA. So you must still use Atom for loading code out of, and saving code into Tabletop Simulator.

## Modules

### Base64

A package for encoding and decoding Base64 binary data.

### ContainerEventsFix

This can be utilized as a work around for a [bug](http://www.berserk-games.com/forums/showthread.php?5461-onObjectEnterContainer-never-fires-for-bottom-card) that presently exists in Tabletop Simulator.

Specifically `onObjectEnterContainer` is only fired for one card, when two cards for a deck. To fix this your cards must each have a script that looks like:

```lua
require("ge_tts/InstanceCollisionProxy")
```

Then in your Global script you can then simply require `ContainerEventsFix`.

### Coroutine

Convenience functions for working with co-routines that are, for example, to be executed every X frames, or every X seconds.

### DropZone

A `Zone` that acts as flexible, extensible and scriptable replacement for TTS snap points. When an object is dropped in `DropZone` the object will be smoothly animated into the center of the zone (and rotated accordingly).

`DropZone` also have an optional `occupantScale` which specifies how dropped objects should be scaled (along the X-axis) when they're dropped in the DropZone, aspect ratio is always preserved. Automatic scaling can be used to provide visual queues about important objects, or rather objects placed in important locations/zones.

To extend `DropZone`'s functionality you can "sub-class" `DropZone` and override the `onEnter`, `onLeave`, `onDrop` and `onPickup` functions as desired.

 `DropZone` is itself a sub-class of `Zone`, so for an example of how you can extend a "class" please refer to `DropZone.ttslua` (or `HandZone.ttslua`).

### EventManager

TTS has several events which are called as global functions on a script. It's fairly common to have several objects or unrelated pieces of code that are interested in these events.

`EventManager` allows several pieces of code to subscribe to the one event. If you have already written global event handler functions you must move their definition _above_ all `ge_tts_require` in the same script otherwise they will interfere with `EventManager`.

### Graph

A package with functions useful for working with node hierarchies e.g. TTS UI ("XML") tables.

### HandZone

A `Zone` that belongs to a player (owner) and corresponds with one of their hands (most games just have the one hand). When instantiated `HandZone` will automatically size itself to encompass the associated TTS hand zone so that you can programatically track cards that are in the players hand.

Typically, to make use of this package you'd create your own package/"class" where you extend `HandZone` and override the `onEnter`, `onLeave`, `onDrop` and `onPickup` functions as desired.

`HandZone` is itself a sub-class of `Zone`, so for an example of how you can extend a "class" please refer to `HandZone.ttslua` (or `DropZone.ttslua`).

### InstanceCollisionProxy

Dependencies: **core**

Used in conjunction with the `ContainerEventsFix` package.

### Logger

A robust logging system with support for log levels and filtering. 

### PlayerDropZone

A `DropZone` that is associated with a particular TTS player, specifically instances have an additional `getOwner()`.

### RemoteLogger

A `Logger` that rather than printing to TTS' console, will HTTP `PUT` a JSON object with `messages` (array of strings) to a URL that you provide when instantiating the `RemoteLogger`.

Using HTTP `PUT` instead of `POST` is pretty severe abuse of HTTP semantics, however we don't have a choice as TTS' HTTP functionality is severely lacking and cannot `POST` JSON.

**WARNING**: The `Content-Type` of the request is `octet-stream` instead of the correct type `application/json`. As mentioned, TTS' HTTP client is extremely poor and does not allow us to set headers.

We don't presently provide a corresponding server, but it's pretty trivial to create your own in Python, Ruby, Node.js etc.

Remote logs could be useful for diagnosing issues your players are running into, however personally I just use it in development as my logs are kept even if TTS crashes, and it's easy to copy and paste data from my logs etc. 

### TableUtils

Several convenience methods to be used in conjunction with tables.

**Warning**: For both performance and semantic reasons, this module will only operate on tables that are either _arrays_ or _hashes/maps_, but not tables that are _both_ simultaneously. Behavior is undefined for tables that contain a key for [1] _as well as_ non-consecutive integer, or non-integer, keys.

### Vector2

2D vector implementation.

### Vector3

3D vector implementation.

### Zone

A wrapper around a TTS scripting zone (`ScriptingTrigger`) that tracks dropped and picked up objects. Objects that have been dropped in the `Zone` are deemed to be occupying and can be retrieved with `getOccupyingObjects()`.

Typically, you'll want to use a `DropZone`, `PlayerDropZone` or `HandZone` rather than `Zone`. However, you may sub-class `Zone` if you wish.
