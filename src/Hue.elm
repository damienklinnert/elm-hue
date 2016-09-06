module Hue exposing (BridgeReference, bridgeRef, LightReference, LightDetails, LightState, LightEffect(..), Alert(..), lightRef, listLights, getLightState, updateLight, LightUpdate, turnOn, turnOff, brightness, hue, saturation, colorTemperature, singleAlert, loopedAlert, noEffect, colorLoopEffect, transition, BridgeReferenceError(..), ErrorDetails, GenericError(..), UpdateLightError(..))

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

@docs BridgeReferenceError

## Generic Hue API Errors

@docs ErrorDetails, GenericError

## Command Specific Hue API Errors

@docs UpdateLightError
-}


import Task as T
import Http as H
import Json.Encode as JE
import Hue.Lights.Decoders as LD


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


{-| Details about a light like identifier, software version and bulb type.
-}
type alias LightDetails =
    { id : String
    , name : String
    , uniqueId : String
    , luminaireUniqueId : Maybe String
    , bulbType : String
    , modelId : String
    , manufacturerName : Maybe String
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
listLights : BridgeReference -> T.Task BridgeReferenceError (Result (List GenericError) (List LightDetails))
listLights (BridgeReference bridge) =
  H.get LD.detailsListResponseDecoder ((bridgeReferenceDataUrl bridge) ++ "/lights")
    |> T.mapError mapHttpError
    |> checkResponseForAuthError
    |> T.map (mapResponse mapErrorsToGenericErrors (List.map mapLightDetails))


{-| Get the state for a given light.
-}
getLightState : LightReference -> T.Task BridgeReferenceError (Result (List GenericError) LightState)
getLightState (LightReference light) =
  H.get LD.stateResponseDecoder ((bridgeReferenceDataUrl light.bridge) ++ "/lights/" ++ light.id)
    |> T.mapError mapHttpError
    |> checkResponseForAuthError
    |> T.map (mapResponse mapErrorsToGenericErrors mapLightState)


encodeEffect : LightEffect -> JE.Value
encodeEffect effect =
  JE.string
    <| case effect of
        NoLightEffect ->
          "none"

        ColorLoopEffect ->
          "colorloop"


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


{-| Apply a list of `LightUpdate`s to a particular light.

The following command will transition a light to a bright red:

    updateLight lightRef [ turnOn, transition 10, hue 0, brightness 254 ]

If the command is successfully sent to the bridge and there are no bridge errors, then `Result.Ok` is returned.
-}
updateLight : LightReference -> List LightUpdate -> T.Task BridgeReferenceError (Result (List UpdateLightError) ())
updateLight (LightReference light) updates =
  H.send
    H.defaultSettings
    { verb = "PUT"
    , headers = []
    , url = (bridgeReferenceDataUrl light.bridge) ++ "/lights/" ++ light.id ++ "/state"
    , body = H.string <| JE.encode 0 <| encodeUpdates updates
    }
    |> H.fromJson LD.multiResponse
    |> T.mapError mapHttpError
    |> checkMultiResponseForAuthError
    |> T.map (mapLightUpdateResponse (LightReference light))


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


{-| Error that occurs preventing proper communication with the bridge.
-}
type BridgeReferenceError
    = Timeout
    | NetworkError
    | UnauthorizedUser ErrorDetails


{-| Details about a Hue API error
-}
type alias ErrorDetails =
    { id : Int
    , description : String
    , details : String
    }


{-| General Hue API error that can be returned from the bridge after a command.
-}
type GenericError
    = GenericError ErrorDetails
    | ResourceNotAvailable ErrorDetails
    | ItemLimit ErrorDetails
    | PortalRequired ErrorDetails
    | InternalError ErrorDetails


{-| Hue API error that can be returned after a `updateLight` command.
General `GenericError` errors can be returned, as well as a `DeviceTurnedOff` error if the device updating is off.

    case error of
        UpdateLightError genericError ->
            case genericError of
                _ ->
                    Debug.log "Generic error occurred. Can handle more specific errors if needed." msg

        DeviceTurnedOff lightRef offError ->
            Debug.log "Device is turned off." msg
-}
type UpdateLightError
    = UpdateLightError GenericError
    | DeviceTurnedOff LightReference ErrorDetails


filterErrors : List LD.SuccessOrError -> List LD.Error
filterErrors successOrErrors =
    let
        isError a =
            case a of
                LD.ErrorValue e ->
                    Just e

                _ ->
                    Nothing
    in
        List.filterMap isError successOrErrors

checkResponseForAuthError : T.Task BridgeReferenceError (LD.Response a) -> T.Task BridgeReferenceError (LD.Response a)
checkResponseForAuthError task =
    task `T.andThen` failResponseIfAuthError


checkMultiResponseForAuthError : T.Task BridgeReferenceError (List LD.SuccessOrError) -> T.Task BridgeReferenceError (List LD.SuccessOrError)
checkMultiResponseForAuthError task =
    task `T.andThen` failMultiResponseIfAuthError


{- If any auth errors are returned from the bridge, fail the task
-}
failAuthError : List LD.Error -> a -> T.Task BridgeReferenceError a
failAuthError errors success =
    let
        isAuthError e =
            if e.type' == 1 then
                True
            else
                False

        authError =
            List.filter isAuthError errors
                |> List.head

    in
        case authError of
            Just authErr ->
                mapErrorDetails authErr
                    |> UnauthorizedUser
                    |> T.fail

            Nothing ->
                T.succeed success


{- Fail the task if the multi success and errors response contains an AuthError
-}
failMultiResponseIfAuthError : List LD.SuccessOrError -> T.Task BridgeReferenceError (List LD.SuccessOrError)
failMultiResponseIfAuthError successOrErrors =
        failAuthError (filterErrors successOrErrors) successOrErrors


{- Fail the task if the response contains an AuthError
-}
failResponseIfAuthError : LD.Response a -> T.Task BridgeReferenceError (LD.Response a)
failResponseIfAuthError response =
    case response of
        LD.ErrorsResponse errors ->
            failAuthError errors (LD.ErrorsResponse errors)

        LD.ValidResponse result ->
            T.succeed (LD.ValidResponse result)



-- Light Responses


mapLightUpdateResponse : LightReference -> List LD.SuccessOrError -> Result (List UpdateLightError) ()
mapLightUpdateResponse lightRef successOrErrors =
    let
        errors =
            filterErrors successOrErrors
    in
        case errors of
            [] ->
                Result.Ok ()

            _ ->
                let
                    errorMapper e =
                        case e.type' of
                            201 ->
                                DeviceTurnedOff lightRef (mapErrorDetails e)

                            _ ->
                                mapErrorDetails e
                                    |> mapErrorToGenericError
                                    |> UpdateLightError
                in
                    Result.Err (List.map errorMapper errors)


{- Maps a response that is either a success or a list of errors
-}
mapResponse : (List LD.Error -> b) -> (a -> c) -> LD.Response a -> Result b c
mapResponse errMapper valueMapper response =
    case response of
        LD.ValidResponse data ->
            Ok (valueMapper data)

        LD.ErrorsResponse errors ->
            Err (errMapper errors)



-- Light Type Mappers


mapLightDetails : LD.LightDetails -> LightDetails
mapLightDetails details =
    LightDetails
        details.id
        details.name
        details.uniqueId
        details.luminaireUniqueId
        details.bulbType
        details.modelId
        details.manufacturerName
        details.softwareVersion


mapLightState : LD.LightState -> LightState
mapLightState state =
    let
        newEffect =
            mapLightEffect state.effect

        newAlert =
            mapAlert state.alert
    in
        LightState
            state.on
            state.brightness
            state.hue
            state.saturation
            newEffect
            state.colorTemperature
            newAlert
            state.reachable


mapAlert : LD.Alert -> Alert
mapAlert alert =
    case alert of
        LD.NoAlert ->
            NoAlert

        LD.SingleAlert ->
            SingleAlert

        LD.LoopedAlert ->
            LoopedAlert


mapLightEffect : LD.LightEffect -> LightEffect
mapLightEffect effect =
    case effect of
        LD.NoLightEffect ->
            NoLightEffect

        LD.ColorLoopEffect ->
            ColorLoopEffect


mapErrorDetails : LD.Error -> ErrorDetails
mapErrorDetails error =
    ErrorDetails
        error.type'
        error.address
        error.description


mapHttpError : H.Error -> BridgeReferenceError
mapHttpError httpError =
    case httpError of
        H.Timeout ->
            Timeout

        _ ->
            NetworkError


mapErrorToGenericError : ErrorDetails -> GenericError
mapErrorToGenericError errorDetails =
    case errorDetails.id of
        3 ->
            ResourceNotAvailable errorDetails

        11 ->
            ItemLimit errorDetails

        12 ->
            PortalRequired errorDetails

        901 ->
            InternalError errorDetails

        _ ->
            GenericError errorDetails


mapErrorsToGenericErrors : List LD.Error -> List GenericError
mapErrorsToGenericErrors errors =
    List.map (mapErrorDetails >> mapErrorToGenericError) errors
