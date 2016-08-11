module Tests.Lights exposing (tests)

import Json.Decode as JD
import ElmTest exposing (..)
import Res.Lights exposing (..)
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
            [ test "Version 1.0 with multiple lights" <|
                testDecoder detailsListDecoder getAllLights__1_0
            , test "No lights available" <|
                testDecoder detailsListDecoder noLights
            ]
