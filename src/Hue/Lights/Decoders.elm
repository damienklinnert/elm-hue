module Hue.Lights.Decoders exposing (..)

import Json.Decode as JD
import Json.Decode exposing ((:=))


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


detailsDecoder : JD.Decoder LightDetails
detailsDecoder =
    JD.object8
        LightDetails
        (JD.succeed "")
        ("name" := JD.string)
        ("uniqueid" := JD.string)
        (JD.maybe ("luminaireuniqueid" := JD.string))
        ("type" := JD.string)
        ("modelid" := JD.string)
        (JD.maybe ("manufacturername" := JD.string))
        ("swversion" := JD.string)


detailsListDecoder : JD.Decoder (List LightDetails)
detailsListDecoder =
    JD.keyValuePairs detailsDecoder |> JD.map (List.map (\( id, m ) -> { m | id = id }))


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


type LightEffect
    = NoLightEffect
    | ColorLoopEffect


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


type Alert
    = NoAlert
    | SingleAlert
    | LoopedAlert


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
