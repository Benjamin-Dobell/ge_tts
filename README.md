# Glass Echidna Tabletop Simulator Core Libraries (ge_tts)

Documentation is a work in progress, pull/merge requests welcome.

## License

Everything in this repository is permissively licensed under the MIT license, please refer to the `LICENSE` file.

## Writing/Using Packages

Tabletop Simulator does not support traditional Lua modules/packages. All Lua code that's to be utilised must be directly included as part of each script.

Luckily there's an official [Atom plugin](https://github.com/Berserk-Games/atom-tabletopsimulator-lua) that supports an additional `#include` "keyword". However, it's not a traditional `#include`/`require` that developers may be used to. It just does direct text replacement, substituting out the `#include <path>` with the contents of the file found at `<path>`.

In the simple case, direct text replacement works well enough. However, as your project grows you'll likely run into name collisions, or rather lack of namespaces. This is because we're simply doing direct text replacement, all the code even `local function` will end up in the one file and variables and function names may start to collide with each other. This particularly problematic when using third-party libraries.

ge_tts offers a solution for this problem in the form of `ge_tts_package` and `ge_tts_require`.

### Creating a package

You define a package like so:

File: `my_prefix/some_package.ttslua`
```lua
ge_tts_package('my_prefix/some_package', function()
	local some_package = {}
	
	some_package.VERSION = '1'
	
	local function localSayHi()
		print('Hiya!')
	end
	
	function some_package.sayHi()
		print('Hi!')
	end
	
	return some_package
end)
```

Here we're creating a package called `my_prefix/some_package`, it's suggested you come up with a unique prefix for all your packages. A company name or domain name is a good choice.

What you've probably noticed is that your package code is wrapped up in a function, with a return value. This function is "lazy evaluated" i.e. It's only executed when another piece of code tries to use this package.

Each package returns a value, typically a lua table that contains public functions and variables.

You use this package like:

File: Global script (`Global.-1.ttslua`)
```lua
#include ge_tts/ge_tts

#include my_prefix/some_package

local my_name_for_some_package = ge_tts_require('my_prefix/some_package')

my_name_for_some_package.sayHi() -- Will print 'Hi!'
print('some_package version = ' .. my_name_for_some_package.VERSION)


-- Both of the following very intentionally won't work, because localSayHi() is
-- scoped inside the package and never exposed publicly.

my_name_for_some_package.localSayHi()
localSayHi()

-- This following also intentionally won't work, because some_package isn't defined publicly

some_package.sayHi()
```

This is great, we're not leaking local functions, we're not stuck using the name `some_package` globally, which could collide with some other `some_package` and we can safely access functions and variables that have intentionally been exposed by the package.

We also `#include`d `ge_tts/ge_tts`, which is where `ge_tts_package` and `ge_tts_require` are defined.

### Includes / Dependencies

The astute reader will have noticed that in the above example we first `#include` the file that defines the package, we then use `ge_tts_require` to actually start using the package.

Individual packages should *not* ever `#include` code from another file. A package that references another package can be written like:

File: `my_prefix/international/some_package.ttslua`
```lua
ge_tts_package('my_prefix/international/some_package', function()
	local TableUtils = ge_tts_require('ge_tts/TableUtils') -- ge_tts comes with its own "standard library" including table helper functions
	
	local english_some_package = ge_tts_require('my_prefix/some_package')

	local some_package = TableUtils.copy(english_some_package)
	
	function some_package.sayGutenTag()
		print('Guten tag!')
	end
	
	return some_package
end)
```

The example above demonstrates a few key concepts.

- We've required `my_prefix/some_package` and given it the name `english_some_package`
- We've created our own local `some_package` which copies `english_some_package` and then exposes `sayGutenTag()` (in addition to `sayHi()`).
- We're using `TableUtils` which come with `ge_tts`.

Now our updated Global script could look like

File: Global script (`Global.-1.ttslua`)
```lua
#include ge_tts/ge_tts -- Should always come first
#include ge_tts/core

#include my_prefix/international/some_package
#include my_prefix/some_package

local some_package = ge_tts_require('my_prefix/some_package')
local international_some_package = ge_tts_require('my_prefix/international/some_package')

some_package.sayHi() -- Will print 'Hi!'

international_some_package.sayGutenTage() -- Will print 'Guten tag!'
international_some_package.sayHi() -- Will also print 'Hi!'
```

In this example we're safely using two packages which internally call themselves `some_package` and we're not running into any name collisions!

We've `#include`d four files:

* `ge_tts/ge_tts` - Necessary to write and include ge_tts packages.
* `ge_tts/core` - This is a convenience file, it is *not* a package. It includes several other files which may be useful
* `my_prefix/international/some_package` - Our new package with `sayGutenTag()`
* `my_prefix/some_package` - Our original package with `sayHi()`

You may have picked up on the fact that `my_prefix/international/some_package` depends on `my_prefix/some_package`, yet we've included `my_prefix/international/some_package` _first!_

Because ge_tts packages are lazy evaluated (when they're first `ge_tts_require`d), you can safely include the files in any order you want!

Actually, if written correctly, packages can also have circular dependencies between each other and work just fine. ge_tts will even detect if you write invalid circular/cyclical packages and raise an error to let you know.

### How do I know which files to `#include`?

If you're using a third-party package, they themselves might have dependencies that you must `#include`. Packages should document their dependencies, however, ge_tts will raise an error to let you know if code tries to require an unknown package.

Effectively, ge_tts automatically lets you know when you're missing an `#include`.

## Included Packages ("Standard Library")

ge_tts comes with a bunch of packages that you may find useful.

Because of the way ge_tts packages are written, if you don't use a particular package, you won't need to `#include` it, so it won't increase the size of your game or have any impact on performance.

#### _Naming Conventions_

We use upper camel-case filenames to indicate packages, lower-case snake-case is used for any other TTS lua which do not define a package.

You're welcome to follow this convention, but you're not obligated to.

### Base64

Dependencies: **core**

A package for encoding and decoding Base64 binary data.

### ContainerEventsFix

Dependencies: **core**

This can be utilized as a work around for a [bug](http://www.berserk-games.com/forums/showthread.php?5461-onObjectEnterContainer-never-fires-for-bottom-card) that presently exists in Tabletop Simulator.

Specifically `onObjectEnterContainer` is only fired for one card, when two cards for a deck. To fix this your cards must each have a script that looks like:

```lua
#include ./ge_tts
#include ./ge_tts/core

#include ./ge_tts/scripts/instance_collision_proxy
```

Then in your Global script you can then simply require `ContainerEventsFix`.

### DropZone

Dependencies: **core**

It's common for card games to have dedicated regions on the table/board where cards should be placed. TTS snap points _can_ be utilized for this task, but `DropZone` is a more flexible and extensible solution.

### EventManager

Part of **core**.

TTS has several events which are called as global functions on a script. It's fairly common to have several objects or unrelated pieces of code that are interested in these events.

`EventManager` allows several pieces of code to subscribe to the one event. If you have already written global event handler functions you must move their definition _above_ all `ge_tts_require` in the same script otherwise they will interfere with `EventManager`.

### HandZone

Dependencies: **core**

A base class that you can use for tracking when cards enter and leave a player's hand. To use this package you'd create your own package/"class" where you extend `HandZone` and override the `onEnter`, `onLeave` and `onDrop` functions. 

Please refer to the source code of `PlayerDropZone` for example of how you can extend a "class".

### Logger

Part of **core**.

A robust logging system with support for log levels and filtering. 

### PlayerDropZone

Dependencies: `DropZone`

A `DropZone` that is associated with a particular TTS player, specifically instances have an additional `getOwner()`.

### RemoteLogger

Dependencies: **core**

A `Logger` that rather printing to TTS' console, will `POST` web requests to a URL that you provide when instantiating the `RemoteLogger`.

We don't presently provide a corresponding server, but it's pretty trivial to create your own in Python, Ruby, Node.js etc.

Remote logs could be useful for diagnosing issues your players are running into, however personally I just use it in development as my logs are kept even if TTS crashes, and it's easy to copy and paste data from my logs etc. 

### TableUtils

Part of **core**.

Several convenience methods to be used in conjunction with tables.

## Other files

### ge_tts

This is the ge_tts entry point, you _must_ include this file to use any other functionality offerred by ge_tts.

It is the *only* file in ge_tts (excluding **scripts**, documented below) which exposes global functions, specifically:

* ge_tts_package
* ge_tts_require
* ge_tts_loaded_packages - You generally won't need to use this function, it is however useful for some advanced use cases.

### core

A convenience file that includes several common packages, those included are documented above.

### Scripts

Code that is designed to be included directly into an Object script in your game, they are _not_ packages.

#### instance_collision_proxy

Dependencies: **core**

Used in conjunction with the `ContainerEventsFix` package.
