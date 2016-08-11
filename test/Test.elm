module Main exposing (..)

import ElmTest exposing (..)
import Tests.Lights as Lights


tests : Test
tests =
    suite "Elm Hue Library Tests"
        [ Lights.tests
        ]


main : Program Never
main =
    runSuiteHtml tests
