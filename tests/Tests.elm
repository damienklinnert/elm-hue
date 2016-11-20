module Tests exposing (..)

import Test exposing (..)
import Tests.Lights as Lights


all : Test
all =
    describe "Elm Hue Library Tests"
        [ Lights.tests
        ]
