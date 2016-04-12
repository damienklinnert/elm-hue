# elm-hue

Control your Philips Hue devices with Elm!

The `Hue` module provides a simple way to query and control your Philips Hue devices from
your Elm application. It empowers you to build a UI for controling your lights in almost no time!

- [license](https://github.com/damienklinnert/elm-hue/issues/blob/master/LICENSE)
- [bug tracker](https://github.com/damienklinnert/elm-hue/issues)
- [source code](https://github.com/damienklinnert/elm-hue)
- [documentation](http://package.elm-lang.org/packages/damienklinnert/elm-hue/latest/)


## Quickstart

This section will walk you through your very first steps with the `Hue` module. At the end, you'll
have a good understanding of this module.

### Preparation: Obtaining Base Url and Username

Before we get started, you'll need to obtain two pieces of information: the **base url** of your
bridge and a valid **username**. If you already have those, you can skip this section. Otherwise
keep reading.

There's a [great cli tool for setting everything up written in ruby](https://github.com/birkirb/hue-cli)
Simply run the following commands to obtain your base url and username.

```bash
gem install hue-cli
hue register
# take a note of the username (the part in brackets), e.g. D4yG2jaaJRlKWriuoeNyD25js8aJ53lslaj73DK7
hue | grep IP
# take a note of the ip and append http://, e.g. http://192.168.1.1
```


### Referencing Your Bridge

In order to communicate with the bridge, we'll need a reference first:

```elm
module Main where

import Hue

-- replace those with your base url and username
baseUrl = "http://192.168.1.1"
username = "D4yG2jaaJRlKWriuoeNyD25js8aJ53lslaj73DK7"

myBridge : Hue.BridgeReference
myBridge = Hue.bridgeRef baseUrl username
```

### Listing Available Lights

We can use the bridge reference to list all available lights by calling `listLights`. Don't forget
to pass the returned `Task` to a `port`.

```elm
module Main where

import Hue
import Debug
import Task
import Graphics.Element as Element

-- replace those with your baseUrl and username
baseUrl = "http://192.168.1.1"
username = "D4yG2jaaJRlKWriuoeNyD25js8aJ53lslaj73DK7"

myBridge = Hue.bridgeRef baseUrl username

port runListLights : Task.Task Hue.Error (List Hue.LightDetails)
port runListLights =
  Hue.listLights myBridge
    |> Task.map (\details -> Debug.log "light details" details)
    >> Task.mapError (\err -> Debug.log "an error occured" err)

main = Element.show "Open your developer tools to see light details"
```

If everything goes well the output will look similar to this:

```
lights:
  [ { id = "5"
  , name = "Hue color lamp 1"
  , uniqueId = "00:93:12:01:00:fb:3a:ff-0b"
  , bulbType = "Extended color light"
  , modelId = "LCT001"
  , manufacturerName = "Philips"
  , softwareVersion = "66009663"
  } ]
```

If you see an error, make sure that:

 - you're still in the same network as the bridge
 - both baseUrl and username have the correct format


### Updating Light State

We can use one of the light ids to create a reference to it like this:

```elm
myLight : Hue.LightReference
myLight = Hue.lightRef myBridge lightIdFromPreviousExample
```

This light reference allows us to control the light. Here's an example that toggles the light on/off
every 4 seconds.

```elm
module Main where

import Hue
import Debug
import Task
import Graphics.Element as Element
import Time


-- replace those with your baseUrl and username
baseUrl = "http://192.168.1.1"
username = "D4yG2jaaJRlKWriuoeNyD25js8aJ53lslaj73DK7"


myBridge = Hue.bridgeRef baseUrl username
myLight = Hue.lightRef myBridge "3"


turnOn =
  Hue.updateLight myLight [ Hue.turnOn ]
    |> Task.map (Debug.log "turned light on")
    >> Task.mapError (Debug.log "an error occured")

turnOff =
  Hue.updateLight myLight [ Hue.turnOff ]
    |> Task.map (Debug.log "turned light off")
    >> Task.mapError (Debug.log "an error occured")


every4Seconds = Time.every (4 * Time.second)
everyOther4Seconds = Time.delay (2 * Time.second) every4Seconds


port runTurnOn : Signal.Signal (Task.Task Hue.Error ())
port runTurnOn = Signal.map (always turnOn) every4Seconds


port runTurnOff : Signal.Signal (Task.Task Hue.Error ())
port runTurnOff = Signal.map (always turnOff) everyOther4Seconds


main =
  Element.show "Open your developer tools to see light details"
```


### What's next?

Check out the other functions on the [Hue module](http://package.elm-lang.org/packages/damienklinnert/elm-hue/latest/Hue)
and build yourself a powerful UI for controling your own lights.