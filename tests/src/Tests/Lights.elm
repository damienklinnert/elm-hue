module Tests.Lights exposing (tests)

import Json.Decode as JD
import Test exposing (..)
import Expect
import Resource.Lights exposing (..)
import Hue.Lights.Decoders exposing (..)


tests : Test
tests =
    describe "Lights decoding"
        [ getAllLightsTest
        , getAllLightsWithStateTest
        , getLightStateTest
        , updateLightResponseTest
        ]


testDecoder : JD.Decoder a -> String -> (() -> Expect.Expectation)
testDecoder decoder str =
    \() ->
        case JD.decodeString decoder str of
            Ok _ ->
                Expect.pass

            Err e ->
                Expect.fail e


getAllLightsTest : Test
getAllLightsTest =
    describe "Get all lights"
        [ test "Version 1.4 with multiple lights" <|
            testDecoder detailsListResponseDecoder getAllLights__1_4
        , test "Version 1.7 with multiple lights" <|
            testDecoder detailsListResponseDecoder getAllLights__1_7
        , test "Version 1.9 with multiple lights" <|
            testDecoder detailsListResponseDecoder getAllLights__1_9
        , test "Version 1.11 with multiple lights" <|
            testDecoder detailsListResponseDecoder getAllLights__1_11
        , test "No lights available" <|
            testDecoder detailsListResponseDecoder noLights
        , test "Authentication error when fetching all lights" <|
            testDecoder detailsListResponseDecoder invalidAuthError
        ]


getAllLightsWithStateTest : Test
getAllLightsWithStateTest =
    describe "Get all lights with state"
        [ test "Version 1.4 with multiple lights" <|
            testDecoder detailsAndStatesResponseDecoder getAllLights__1_4
        , test "Version 1.7 with multiple lights" <|
            testDecoder detailsAndStatesResponseDecoder getAllLights__1_7
        , test "Version 1.9 with multiple lights" <|
            testDecoder detailsAndStatesResponseDecoder getAllLights__1_9
        , test "Version 1.11 with multiple lights" <|
            testDecoder detailsAndStatesResponseDecoder getAllLights__1_11
        , test "No lights available" <|
            testDecoder detailsAndStatesResponseDecoder noLights
        , test "Authentication error when fetching all lights" <|
            testDecoder detailsAndStatesResponseDecoder invalidAuthError
        ]


getLightStateTest : Test
getLightStateTest =
    describe "Get Light state"
        [ test "Version 1.4" <|
            testDecoder stateResponseDecoder lightState__1_4
        , test "Version 1.11" <|
            testDecoder stateResponseDecoder lightState__1_11
        , test "Auth error" <|
            testDecoder stateResponseDecoder invalidAuthError
        ]


updateLightResponseTest : Test
updateLightResponseTest =
    describe "Parse light update response"
        [ test "Multi error and success response" <|
            testDecoder multiResponse multiSuccessAndErrorLightUpdateResponse
        , test "Single successful response" <|
            testDecoder multiResponse singleSuccessLightUpdateResponse
        , test "Multiple successful responses" <|
            testDecoder multiResponse multiSuccessLightUpdateResponse
        , test "All success value types" <|
            testDecoder multiResponse allSuccessLightUpdateResponseTypes
        , test "Single error response" <|
            testDecoder multiResponse invalidAuthError
        ]
