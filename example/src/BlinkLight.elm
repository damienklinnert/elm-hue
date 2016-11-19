-- This example queries your light details and then repeatedly blinks one light by turning it on and off.


module Main exposing (..)

import Debug
import Html exposing (text, program)
import Task
import Time
import Hue
import Hue.Errors as Errors


-- IMPORTANT: Configure your bridge and light details here before running this program!


baseUrl =
    "http://192.168.1.1"


username =
    "D4yG2jaaJRlKWriuoeNyD25js8aJ53lslaj73DK7"


myBridge =
    Hue.bridgeRef baseUrl username


myLight =
    Hue.lightRef myBridge "3"



-- This is how you list all available lights


listLightsTask : Task.Task Errors.BridgeReferenceError (Result (List Errors.GenericError) (List Hue.LightDetails))
listLightsTask =
    Hue.listLights myBridge
        |> Task.map (Debug.log "light details")
        >> Task.mapError (Debug.log "an error occured")


listLightsCmd : Cmd Msg
listLightsCmd =
    let
        handler res =
            case res of
                Ok v ->
                    handleListLightsResponse v
                Err e ->
                    handleBridgeCommandFailure e
    in
        Task.attempt handler listLightsTask


-- This is how you blink the lights


turnOnTask =
    Hue.updateLight myLight [ Hue.turnOn ]
        |> Task.map (Debug.log "turned light on")


turnOffTask =
    Hue.updateLight myLight [ Hue.turnOff ]
        |> Task.map (Debug.log "turned light off")


turnOnCmd : Cmd Msg
turnOnCmd =
    let
        handler res =
            case res of
                Ok v ->
                    handleUpdateResponse v
                Err e ->
                    handleBridgeCommandFailure e
    in
        Task.attempt handler turnOnTask


turnOffCmd : Cmd Msg
turnOffCmd =
    let
        handler res =
            case res of
                Ok v ->
                    handleUpdateResponse v
                Err e ->
                    handleBridgeCommandFailure e
    in
        Task.attempt handler turnOffTask


toggleEvery4Seconds : Sub Msg
toggleEvery4Seconds =
    Time.every (4 * Time.second) (always ToggleCmd)



-- Error handling


handleBridgeCommandFailure : Errors.BridgeReferenceError -> Msg
handleBridgeCommandFailure error =
    case error of
        Errors.UnauthorizedUser info ->
            AuthError

        _ ->
            Error


handleListLightsResponse : Result (List Errors.GenericError) (List Hue.LightDetails) -> Msg
handleListLightsResponse response =
    case response of
        Result.Ok lights ->
            Noop

        Result.Err errors ->
            Error


handleUpdateResponse : Result (List Errors.UpdateLightError) () -> Msg
handleUpdateResponse response =
    case response of
        Result.Ok _ ->
            Noop

        Result.Err errors ->
            let
              commands =
                List.map
                    (\e ->
                        case e of
                            Errors.UpdateLightError genericError ->
                                case genericError of
                                    Errors.ResourceNotAvailable err ->
                                        Debug.log ("Resource error " ++ err.address ++ " " ++ err.description) Noop

                                    _ ->
                                        Debug.log ("generic error " ++ (toString genericError)) Noop

                            Errors.DeviceTurnedOff lightId offError ->
                                Debug.log ("Device " ++ lightId ++ " turned off. Turn on device first") Noop
                    )
                    errors
            in
                if List.all (\cmd -> cmd == Noop) commands then
                    Noop
                else
                    Error



-- Boilerplate to set up an application that blinks a light.


type alias Model =
    { willTurnOn : Bool
    }


type Msg
    = Noop
    | ToggleCmd
    | AuthError
    | Error


update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )

        ToggleCmd ->
            let
                cmd =
                    if model.willTurnOn then
                        turnOnCmd
                    else
                        turnOffCmd
            in
                ( { willTurnOn = not model.willTurnOn }, cmd )

        AuthError ->
            ( { model | willTurnOn = False }, Cmd.none)

        Error ->
            ( model, Cmd.none)


main : Program Never Model Msg
main =
    program
        { init = ( { willTurnOn = True }, listLightsCmd )
        , update = update
        , view = (\_ -> text "Configure your bridge details, then open your developer tools and see your light details")
        , subscriptions = always toggleEvery4Seconds
        }
