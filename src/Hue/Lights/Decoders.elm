module Hue.Lights.Decoders exposing (..)

import Hue.Lights as Lights
import Json.Decode as JD
import Json.Decode exposing ((:=))


detailsDecoder : JD.Decoder Lights.LightDetails
detailsDecoder =
    JD.object7
        Lights.LightDetails
        (JD.succeed "")
        ("name" := JD.string)
        ("uniqueid" := JD.string)
        ("type" := JD.string)
        ("modelid" := JD.string)
        ("manufacturername" := JD.string)
        ("swversion" := JD.string)


detailsListDecoder : JD.Decoder (List Lights.LightDetails)
detailsListDecoder =
    JD.keyValuePairs detailsDecoder |> JD.map (List.map (\( id, m ) -> { m | id = id }))


stateDecoder : JD.Decoder Lights.LightState
stateDecoder =
    JD.object8
        Lights.LightState
        (JD.at [ "state", "on" ] JD.bool)
        (JD.at [ "state", "bri" ] JD.int)
        (JD.at [ "state", "hue" ] JD.int)
        (JD.at [ "state", "sat" ] JD.int)
        (JD.at [ "state", "effect" ] effectDecoder)
        (JD.at [ "state", "ct" ] JD.int)
        (JD.at [ "state", "alert" ] alertDecoder)
        (JD.at [ "state", "reachable" ] JD.bool)


effectDecoder : JD.Decoder Lights.LightEffect
effectDecoder =
    JD.map
        (\x ->
            case x of
                "none" ->
                    Lights.NoLightEffect

                "colorloop" ->
                    Lights.ColorLoopEffect

                _ ->
                    Debug.crash "Received unexpected light effect"
        )
        JD.string


alertDecoder : JD.Decoder Lights.Alert
alertDecoder =
    JD.map
        (\x ->
            case x of
                "none" ->
                    Lights.NoAlert

                "select" ->
                    Lights.SingleAlert

                "lselect" ->
                    Lights.LoopedAlert

                _ ->
                    Debug.crash "Received unknown light alert"
        )
        JD.string
