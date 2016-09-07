module Hue.Errors exposing (BridgeReferenceError(..), ErrorDetails, GenericError(..), UpdateLightError(..))

{-| Hue Bridge Errors

@docs BridgeReferenceError

## Generic Hue API Errors

@docs ErrorDetails, GenericError

## Command Specific Hue API Errors

@docs UpdateLightError
-}


{-| Error that occurs preventing proper communication with the bridge.

    case error of
        UnauthorizedUser info ->
            Debug.log ("Needs authorization to use " ++ info.address) msg

        _ ->
            Debug.log "Network error" msg
-}
type BridgeReferenceError
    = Timeout
    | NetworkError
    | UnauthorizedUser ErrorDetails


{-| Details about a Hue API error

    ErrorDetails 201 "/lights/1/state/bri" "parameter, bri, is not modifiable. Device is set to off."
-}
type alias ErrorDetails =
    { id : Int
    , address : String
    , description : String
    }


{-| General Hue API error that can be returned from the bridge after a command.
    
    case error of
        ResourceNotAvailable err ->
            Debug.log ("Resource error: " ++ err.description ++ " " ++ err.details) msg

        _ ->
            Debug.log "Error occurred" msg
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
    | DeviceTurnedOff String ErrorDetails
