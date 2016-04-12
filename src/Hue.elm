module Hue (BridgeReference, bridgeRef, LightReference, lightRef, listLights, LightDetails, getLightState, LightState, LightEffect(..), Alert(..), updateLight, LightUpdate, turnOn, turnOff, brightness, hue, saturation, colorTemperature, singleAlert, loopedAlert, noEffect, colorLoopEffect, transition, Error) where

{-| Control your Philips Hue devices with Elm!

Check the [README for a general introduction into this module](http://package.elm-lang.org/packages/damienklinnert/elm-hue/latest/).

# Bridge

## Referencing the Bridge
@docs BridgeReference, bridgeRef

# Lights

## Referencing Lights
@docs LightReference, lightRef

## Querying Light Details
@docs listLights, LightDetails

## Retrieving Light State
@docs getLightState, LightState, LightEffect, Alert

## Updating Light State
@docs updateLight, LightUpdate, turnOn, turnOff, brightness, hue, saturation, colorTemperature, singleAlert, loopedAlert, noEffect, colorLoopEffect, transition

# Errors

@docs Error
-}

import Task as T
import Http as H
import Json.Decode as JD
import Json.Decode exposing ((:=))
import Json.Encode as JE


{-| Used to identify and reference a particular bridge.
-}
type BridgeReference
  = BridgeReference BridgeReferenceData


type alias BridgeReferenceData =
  { baseUrl : String
  , username : String
  }


{-| Create a reference to a bridge by providing the bridge base url and your username.

    bridgeRef "http://192.168.1.1" "A2iasDJs123fi793uiSh"

If you don't yet know the bridge base url or your username,
[check the readme for detailed instructions](http://package.elm-lang.org/packages/damienklinnert/elm-hue/latest/).
-}
bridgeRef : String -> String -> BridgeReference
bridgeRef baseUrl username =
  BridgeReference { baseUrl = baseUrl, username = username }


bridgeReferenceDataUrl : BridgeReferenceData -> String
bridgeReferenceDataUrl bridge =
  bridge.baseUrl ++ "/api/" ++ bridge.username



-- Lights


{-| Used to identify and reference a particular light.
-}
type LightReference
  = LightReference LightReferenceData


type alias LightReferenceData =
  { bridge : BridgeReferenceData
  , id : String
  }


{-| Create a reference to a light by specifying it's bridge and id.

The id can be obtained by calling `listLights` and looking at the `id` field.

To create a reference to the light with id `"2"`, you can do:

    lightRef myBridge "2"
-}
lightRef : BridgeReference -> String -> LightReference
lightRef (BridgeReference bridge) lightId =
  LightReference { bridge = bridge, id = lightId }


{-| List details about all lights connected to a particular bridge.
-}
listLights : BridgeReference -> T.Task Error (List LightDetails)
listLights (BridgeReference bridge) =
  H.get detailsListDecoder ((bridgeReferenceDataUrl bridge) ++ "/lights")
    |> T.mapError (always GenericError)


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


detailsDecoder : JD.Decoder LightDetails
detailsDecoder =
  JD.object7
    LightDetails
    (JD.succeed "")
    ("name" := JD.string)
    ("uniqueid" := JD.string)
    ("type" := JD.string)
    ("modelid" := JD.string)
    ("manufacturername" := JD.string)
    ("swversion" := JD.string)


detailsListDecoder : JD.Decoder (List LightDetails)
detailsListDecoder =
  JD.keyValuePairs detailsDecoder |> JD.map (List.map (\( id, m ) -> { m | id = id }))


{-| Get the state for a given light.
-}
getLightState : LightReference -> T.Task Error LightState
getLightState (LightReference light) =
  H.get stateDecoder ((bridgeReferenceDataUrl light.bridge) ++ "/lights/" ++ light.id)
    |> T.mapError (always GenericError)


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


stateDecoder : JD.Decoder LightState
stateDecoder =
  JD.object8
    LightState
    (JD.at [ "state", "on" ] JD.bool)
    (JD.at [ "state", "bri" ] JD.int)
    (JD.at [ "state", "hue" ] JD.int)
    (JD.at [ "state", "sat" ] JD.int)
    (JD.at [ "state", "effect" ] effectDecoder)
    (JD.at [ "state", "ct" ] JD.int)
    (JD.at [ "state", "alert" ] alertDecoder)
    (JD.at [ "state", "reachable" ] JD.bool)


{-| A light can have the `ColorLoopEffect` enabled, which means that the light will cycle through
all hues, while keeping brightness and saturation values.
-}
type LightEffect
  = NoLightEffect
  | ColorLoopEffect


encodeEffect : LightEffect -> JE.Value
encodeEffect effect =
  JE.string
    <| case effect of
        NoLightEffect ->
          "none"

        ColorLoopEffect ->
          "colorloop"


effectDecoder : JD.Decoder LightEffect
effectDecoder =
  JD.map
    (\x ->
      case x of
        "none" ->
          NoLightEffect

        "colorloop" ->
          ColorLoopEffect

        _ ->
          Debug.crash "Received unexpected light effect"
    )
    JD.string


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


encodeAlert : Alert -> JE.Value
encodeAlert alert =
  JE.string
    <| case alert of
        NoAlert ->
          "none"

        SingleAlert ->
          "select"

        LoopedAlert ->
          "lselect"


alertDecoder : JD.Decoder Alert
alertDecoder =
  JD.map
    (\x ->
      case x of
        "none" ->
          NoAlert

        "select" ->
          SingleAlert

        "lselect" ->
          LoopedAlert

        _ ->
          Debug.crash "Received unknown light alert"
    )
    JD.string


{-| Apply a list of `LightUpdate`s to a particular light.

The following command will transition a light to a bright red:

    updateLight lightRef [ turnOn, transition 10, hue 0, brightness 254 ]
-}
updateLight : LightReference -> List LightUpdate -> T.Task Error ()
updateLight (LightReference light) updates =
  H.send
    H.defaultSettings
    { verb = "PUT"
    , headers = []
    , url = (bridgeReferenceDataUrl light.bridge) ++ "/lights/" ++ light.id ++ "/state"
    , body = H.string <| JE.encode 0 <| encodeUpdates updates
    }
    |> T.mapError (always GenericError)
    >> T.map (always ())


{-|
  A `LightUpdate` describes a single change to a light's state. To actually perform a `LightUpdate`,
  pass a list of updates to the `updateLight` function.

  To describe a `1s` transition to a bright red, you can specify:

      [ turnOn, transition 10, hue 0, brightness 254 ]
-}
type LightUpdate
  = SetOn Bool
  | SetBrightness Int
  | SetHue Int
  | SetSaturation Int
  | SetColorTemperature Int
  | SetAlert Alert
  | SetEffect LightEffect
  | SetTransitionTime Int


encodeUpdate : LightUpdate -> ( String, JE.Value )
encodeUpdate update =
  case update of
    SetOn b ->
      ( "on", JE.bool b )

    SetBrightness i ->
      ( "bri", JE.int i )

    SetHue i ->
      ( "hue", JE.int i )

    SetSaturation i ->
      ( "sat", JE.int i )

    SetColorTemperature i ->
      ( "ct", JE.int i )

    SetAlert alert ->
      ( "alert", encodeAlert alert )

    SetEffect effect ->
      ( "effect", encodeEffect effect )

    SetTransitionTime t ->
      ( "transitiontime", JE.int t )


encodeUpdates : List LightUpdate -> JE.Value
encodeUpdates updates =
  List.map encodeUpdate updates |> JE.object


{-| Turn light on.
-}
turnOn : LightUpdate
turnOn =
  SetOn True


{-| Turn light off.
-}
turnOff : LightUpdate
turnOff =
  SetOn False


{-| Set light to the given brightness.

The brightness can range from `1` (minimal brightness) to `254` (maximal brightness).
A brightness of `1` doesn't turn the light off. Use `turnOff` instead.
-}
brightness : Int -> LightUpdate
brightness i =
  SetBrightness i


{-| Set light to the given hue value.

Imagine arranging all colors around a circle (a color wheel). On that circle, a value of `0` will
result in red, `25500` in green and `46920` in blue. Values in between result in mixed colors,
e.g. `10710` being yellow. When the value reaches `65535`, you've reached the starting point on the
circle, so you'll get red again.
-}
hue : Int -> LightUpdate
hue i =
  SetHue i


{-| Set light to the given saturation.

The saturation can range from `0` (minimally saturated, white) to `254` (fully colored).
-}
saturation : Int -> LightUpdate
saturation i =
  SetSaturation i


{-| Set the Mired Color temperature of the light.

A light should be capable of a value of `153` (6500K) to `500` (2000K).
-}
colorTemperature : Int -> LightUpdate
colorTemperature i =
  SetColorTemperature i


{-| The light will perform a single, smooth transition up to a higher brightness and back to the
original again.
-}
singleAlert : LightUpdate
singleAlert =
  SetAlert SingleAlert


{-| The light will perform multiple, smooth transitions up to a higher brightness and back to the
original again for a period of `15` seconds.
-}
loopedAlert : LightUpdate
loopedAlert =
  SetAlert LoopedAlert


{-| Turn off all effects on the light.
-}
noEffect : LightUpdate
noEffect =
  SetEffect NoLightEffect


{-| Sets the colorloop effect on the light.

The light will cycle through all hues, while keeping brightness and saturation values.
-}
colorLoopEffect : LightUpdate
colorLoopEffect =
  SetEffect ColorLoopEffect


{-| Specify the duration for the transition between the light's current and updated state.

A value of `1` will create a `100ms` transition, a value of `10` will create a `1s` transition.

The default is `4` (`400ms`).
-}
transition : Int -> LightUpdate
transition t =
  SetTransitionTime t



-- Errors


{-| Something went wrong.
-}
type Error
  = GenericError
