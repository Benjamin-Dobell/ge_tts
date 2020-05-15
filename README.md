# Glass Echidna Tabletop Simulator Libraries

Documentation is a work in progress, pull/merge requests welcome.

## License

Everything in this repository is permissively licensed under the MIT license, please refer to the `LICENSE` file.

## Discord

If you'd like to discuss ge_tts, you can do so on the [TTS Community Discord](https://discord.gg/YwD22SM).

### EmmyLua and Jetbrains IntelliJ IDEA

For development of your TTS mod we highly recommend using Jetbrains IntelliJ IDEA with a significantly enhanced [EmmyLua fork](https://github.com/Benjamin-Dobell/tts-types/releases) to write your code, instead of (or rather in conjunction with) Atom and the Atom TTS plugin.

[IntelliJ Community Edition](https://www.jetbrains.com/idea/download/) and EmmyLua are both free, and offer significantly more advanced Lua editing capabilities than Atom.

Most importantly, we've included EmmyLua type definitions for our APIs. This means that when you use our types, function and variable names will auto-complete. Additionally, when using EmmyLua you'll want [Tabletop Simulator EmmyLua Types](https://github.com/Benjamin-Dobell/tts-types) which enable auto-completion _and_ type checking.

_However_, at present there is not yet a Tabletop Simulator plugin available for Jetbrains IntelliJ IDEA. So you must still use Atom for loading code out of, and saving code into Tabletop Simulator.

## Modules

These modules are written as standard Lua modules. In order to use these modules you must [require](https://www.lua.org/pil/8.1.html) them.

The official Atom plugin has built-in support for `require`. Otherwise, if your IDE doesn't support it, you can use [luabundler](https://github.com/Benjamin-Dobell/luabundler) from command line. However, this is an advanced solution, Atom is recommended for pushing code to TTS.

### Base64

A package for encoding and decoding Base64 binary data.

### Coroutine

Convenience functions for working with co-routines that are, for example, to be executed every X frames, or every X seconds.

### Debug

Simply utility to facilitate debugging within TTS.

#### `Debug.createGlobals(prefix = "")`

Registers all `require()`d ge_tts types as global variables so they can easily used from TTS' console.

e.g. If you include `Debug.createGlobals()` at the bottom of your script

```
/execute
```

### DropZone

A `Zone` that acts as flexible, extensible and scriptable replacement for TTS snap points. When an object is dropped in `DropZone` the object will be smoothly animated into the center of the zone (and rotated accordingly).

`DropZone` also have an optional `occupantScale` which specifies how dropped objects should be scaled (along the X-axis) when they're dropped in the DropZone, aspect ratio is always preserved. Automatic scaling can be used to provide visual queues about important objects, or rather objects placed in important locations/zones.

To extend `DropZone`'s functionality you can "sub-class" `DropZone` and override the `onEnter`, `onLeave`, `onDrop` and `onPickup` functions as desired.

 `DropZone` is itself a sub-class of `Zone`, so for an example of how you can extend a "class" please refer to `DropZone.ttslua` (or `HandZone.ttslua`).

### EventManager

TTS has several events which are called as global functions on a script. It's fairly common to have several objects or unrelated pieces of code that are interested in these events.

`EventManager` allows several pieces of code to subscribe to the one event. If you have already written global event handler functions you must move their definition _above_ any `require()` of ge_tts modules in the same script, otherwise your exising handlers will interfere with `EventManager`.

### Graph

A package with functions useful for working with node hierarchies e.g. TTS UI ("XML") tables.

### HandZone

A `Zone` that belongs to a player (owner) and corresponds with one of their hands (most games just have the one hand). When instantiated `HandZone` will automatically size itself to encompass the associated TTS hand zone so that you can programatically track cards that are in the players hand.

Typically, to make use of this package you'd create your own package/"class" where you extend `HandZone` and override the `onEnter`, `onLeave`, `onDrop` and `onPickup` functions as desired.

`HandZone` is itself a sub-class of `Zone`, so for an example of how you can extend a "class" please refer to `HandZone.ttslua` (or `DropZone.ttslua`).

### Http

A simple (but functionally complete) HTTP client that works in conjunction with [tts-proxy](https://github.com/Benjamin-Dobell/tts-proxy).

The Http module will automatically encode/decode JSON, otherwise you can provide a string and specify headers yourself. You may also provide an array of number, which represent bytes if the request body should be an octet-stream.

### Logger

A robust logging system with support for log levels and filtering.

### PlayerDropZone

A `DropZone` that is associated with a particular TTS player, specifically instances have an additional `getOwner()`.

### RemoteLogger

A `Logger` that rather than printing to TTS' console, will HTTP `PUT` a JSON object with `messages` (array of strings) to a URL that you provide when instantiating the `RemoteLogger`.

Using HTTP `PUT` instead of `POST` is pretty severe abuse of HTTP semantics, however we don't have a choice as TTS' HTTP functionality is severely lacking and cannot `POST` JSON.

**Warning**: The `Content-Type` of the request is `octet-stream` instead of the correct type `application/json`. As mentioned, TTS' HTTP client is extremely poor and does not allow us to set headers.

We don't presently provide a corresponding server, but it's pretty trivial to create your own in Python, Ruby, Node.js etc.

Remote logs could be useful for diagnosing issues your players are running into, however personally I just use it in development as my logs are kept even if TTS crashes, and it's easy to copy and paste data from my logs etc.

### SaveManager

SaveManager allows modules/files to independently maintain their own saved state, without conflicting with other saved state from other modules/files.

### SaveManager

SaveManager allows modules/files to independently maintain their own saved state, without conflicting with other saved state from other modules/files. 

### TableUtils

Several convenience methods to be used in conjunction with tables.

**Warning**: For both performance and semantic reasons, this module will only operate on tables that are either _arrays_ or _hashes/maps_, but not tables that are _both_ simultaneously. Behavior is undefined for tables that contain a key for [1] _as well as_ non-consecutive integer, or non-integer, keys.

### Vector2

2D vector implementation.

### Vector3

3D vector implementation.

This was written before TTS had its own `Vector` class and is used through-out this library. You may pass `Vector3` to any TTS method that accepts a vector. However, it's worth keeping in mind that our methods return a `Vector3`, whilst TTS's own methods return `Vector`. 

In general TTS' `Vector` and our `Vector3` offer a similar set of functionality, however you can call `Vector3` methods the same way you'd call methods on any complex type in TTS API i.e. `vector1.add(vector2)`, where as TTS' `Vector` requres you to do `vector1:add(vector2)`.

Additionally, all `Vector3` methods will happily accept a `Vector3`, a `Vector`, a table with entries `x`, `y` and `z`, or a table with entries `[1]`, `[2]` and `[3]` as arguments. Where as the TTS-provided `Vector` is a bit more restrictive and will only accept arguments that are also `Vector` e.g. 

```lua
local v = Vector()
v:scale({1, 3, 1}) -- This will throw an error

local v3 = Vector3()
v3.scale({1, 3, 1}) -- This works fine, as does...
v3.scale(v)
v3.scale({x = 1, y = 3, z = 1})
```

### Zone

A wrapper around a TTS scripting trigger (`ScriptingTrigger`) that tracks dropped and picked up objects. Objects that have been dropped in the `Zone` are deemed to be occupying and can be retrieved with `getOccupyingObjects()`.

Typically, you'll want to use a `DropZone`, `PlayerDropZone` or `HandZone` rather than `Zone`. However, you may sub-class `Zone` if you wish.
