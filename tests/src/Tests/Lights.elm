module Tests.Lights exposing (tests)

import Json.Decode as JD
import ElmTest exposing (..)
import Resource.Lights exposing (..)
import Hue.Lights.Decoders exposing (..)


tests : Test
tests =
    suite "Lights decoding"
        [ getAllLightsTest
        ]


getAllLightsTest : Test
getAllLightsTest =
    let
        testDecoder decoder str =
            case JD.decodeString decoder str of
                Ok _ ->
                    pass

                Err e ->
                    fail e
    in
        suite "Get all lights"
            [ test "Version 1.4 with multiple lights"
                <| testDecoder detailsListDecoder getAllLights__1_4
            , test "Version 1.7 with multiple lights"
                <| testDecoder detailsListDecoder getAllLights__1_7
            , test "Version 1.9 with multiple lights"
                <| testDecoder detailsListDecoder getAllLights__1_9
            , test "Version 1.11 with multiple lights"
                <| testDecoder detailsListDecoder getAllLights__1_11
            , test "No lights available"
                <| testDecoder detailsListDecoder noLights
            ]
