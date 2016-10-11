module Hue.Lights.Decoders
    exposing
        ( Response(..)
        , LightDetails
        , detailsResponseDecoder
        , detailsListResponseDecoder
        , detailsAndStatesResponseDecoder
        , LightState
        , stateResponseDecoder
        , LightEffect(..)
        , effectResponseDecoder
        , Alert(..)
        , alertResponseDecoder
        , Error
        , Success
        , SuccessOrError(..)
        , multiResponse
        )

import Json.Decode as JD
import Json.Decode exposing ((:=))


type Response a
    = ErrorsResponse (List Error)
    | ValidResponse a


{- Helper function that decodes either a list of errors or a response decoder
 -}
responseDecoder : JD.Decoder a -> JD.Decoder (Response a)
responseDecoder responseDecoder =
    JD.oneOf
        [ JD.map ValidResponse responseDecoder
        , JD.map ErrorsResponse errorsDecoder
        ]


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


detailsResponseDecoder : JD.Decoder (Response LightDetails)
detailsResponseDecoder =
    responseDecoder detailsDecoder


detailsListDecoder : JD.Decoder (List LightDetails)
detailsListDecoder =
    JD.keyValuePairs detailsDecoder |> JD.map (List.map (\( id, m ) -> { m | id = id }))


detailsListResponseDecoder : JD.Decoder (Response (List LightDetails))
detailsListResponseDecoder =
    responseDecoder detailsListDecoder


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


stateResponseDecoder : JD.Decoder (Response LightState)
stateResponseDecoder =
    responseDecoder stateDecoder


detailAndStateDecoder : JD.Decoder ( LightDetails, LightState )
detailAndStateDecoder =
    JD.object2
        (,)
        detailsDecoder
        stateDecoder


detailsAndStatesDecoder : JD.Decoder (List ( LightDetails, LightState ))
detailsAndStatesDecoder =
    let
        updateId id ( details, state ) =
            ( { details | id = id }, state )
    in
        JD.keyValuePairs detailAndStateDecoder
            |> JD.map (List.map (\( id, data ) -> updateId id data))


detailsAndStatesResponseDecoder : JD.Decoder (Response (List ( LightDetails, LightState )))
detailsAndStatesResponseDecoder =
    responseDecoder detailsAndStatesDecoder


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


effectResponseDecoder : JD.Decoder (Response LightEffect)
effectResponseDecoder =
    responseDecoder effectDecoder


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


alertResponseDecoder : JD.Decoder (Response Alert)
alertResponseDecoder =
    responseDecoder alertDecoder


type alias Error =
    { type' : Int
    , address : String
    , description : String
    }


errorDecoder : JD.Decoder Error
errorDecoder =
    JD.at [ "error" ] <|
        JD.object3
            Error
            ("type" := JD.int)
            ("address" := JD.string)
            ("description" := JD.string)


errorsDecoder : JD.Decoder (List Error)
errorsDecoder =
    JD.list errorDecoder


type alias Success =
    { command : String }


{- Decodes a successful response command in the form of
   [ {"success":{ any string url : any value type } } ]

   parses the "success" and returns the key url.
-}
successDecoder : JD.Decoder Success
successDecoder =
    let
        -- Possible success response types
        allTypesDecoder =
            JD.oneOf
                [ JD.map toString JD.string
                , JD.map toString JD.bool
                , JD.map toString JD.int
                , JD.map toString JD.float
                , JD.map toString (JD.list JD.float)
                ]

        firstValue valuePairs =
            case List.head valuePairs of
                Just pair ->
                    fst pair
                        |> Success
                        |> JD.succeed

                Nothing ->
                    -- Could not parse value, but it was still a Success response object
                    JD.succeed (Success "unknown")
    in
        JD.keyValuePairs allTypesDecoder `JD.andThen` firstValue |> JD.at [ "success" ]


type SuccessOrError
    = SuccessValue Success
    | ErrorValue Error


{- A response of a list that may contain errors and success values
 -}
multiResponse : JD.Decoder (List SuccessOrError)
multiResponse =
    JD.list <|
        JD.oneOf
            [ JD.map ErrorValue errorDecoder
            , JD.map SuccessValue successDecoder
            ]
