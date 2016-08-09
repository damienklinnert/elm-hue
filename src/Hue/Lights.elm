module Hue.Lights exposing (LightDetails, LightState, LightEffect(..), Alert(..))

{-| Hue Light Types

## Representing Light Details
@docs LightDetails

## Representing Light State
@docs LightState, LightEffect, Alert
-}


{-| Details about a light like identifier, software version and bulb type.
-}
type alias LightDetails =
    { id : String
    , name : String
    , uniqueId : String
    , bulbType : String
    , modelId : String
    , manufacturerName : String
    , softwareVersion : String
    }


{-| Describes the current state of a light.

 - `on`: is this light turned on?
 - `brightness`: a range from `1` (minimal brightness) to `254` (maximal brightness)
 - `hue`: a range from `0` to `65535`, with both of them resulting in red, `25500` in green and
   `46920` in blue
 - `saturation`: range from `0` (white) to `254` (fully colored)
 - `colorTemperature`: The Mired Color temperature
 - `reachable`: is the light reachable?
-}
type alias LightState =
    { on : Bool
    , brightness : Int
    , hue : Int
    , saturation : Int
    , effect : LightEffect
    , colorTemperature : Int
    , alert : Alert
    , reachable : Bool
    }


{-| A light can have the `ColorLoopEffect` enabled, which means that the light will cycle through
all hues, while keeping brightness and saturation values.
-}
type LightEffect
    = NoLightEffect
    | ColorLoopEffect


{-| A temporary change to a light's state.

 - `NoAlert`: Disable any existing alerts.
 - `SingleAlert`: The light will perform a single, smooth transition up to a higher brightness and
   back to the original again.
 - `LoopedAlert`: The light will perform multiple, smooth transitions up to a higher brightness and
   back to the original again for a period of `15` seconds.
-}
type Alert
    = NoAlert
    | SingleAlert
    | LoopedAlert
