module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode exposing (..)


type alias Model =
    Selection


type Msg
    = Select Selection
    | NoOp


type Selection
    = All
    | Box Int
    | Row Int Int
    | Item Int Int Int
    | Clear


main =
    Html.beginnerProgram
        { model = initialModel
        , update = update
        , view = view
        }


initialModel : Model
initialModel =
    Clear


update : Msg -> Model -> Model
update msg model =
    case msg of
        Select selection ->
            selection

        NoOp ->
            model


view : Model -> Html Msg
view model =
    div
        [ classList
            [ ( "main", True )
            , ( "selected", model == All )
            ]
        ]
        (List.map
            (box model)
            (List.range 1 3)
        )


box : Selection -> Int -> Html Msg
box selection box =
    div
        [ classList
            [ ( "box", True )
            , ( "selected", selection == Box box )
            ]
        ]
        (List.map
            (row selection box)
            (List.range 1 3)
        )


row : Selection -> Int -> Int -> Html Msg
row selection box row =
    div
        [ classList
            [ ( "row", True )
            , ( "selected", selection == Row box row )
            ]
        ]
        (List.map
            (item selection box row)
            (List.range 1 3)
        )


item : Selection -> Int -> Int -> Int -> Html Msg
item selection box row item =
    div
        [ onMultiClick (clickMsg box row item)
        , classList
            [ ( "item", True )
            , ( "selected", selection == Item box row item )
            ]
        ]
        []


onMultiClick : (Maybe Int -> Msg) -> Attribute Msg
onMultiClick intToMsg =
    maybe (field "detail" int)
        |> Json.Decode.map intToMsg
        |> on "click"


clickMsg : Int -> Int -> Int -> Maybe Int -> Msg
clickMsg box row item s =
    case s of
        Just 1 ->
            Select (Item box row item)

        Just 2 ->
            Select (Row box row)

        Just 3 ->
            Select (Box box)

        Just _ ->
            Select All

        Nothing ->
            Select (Item box row item)
