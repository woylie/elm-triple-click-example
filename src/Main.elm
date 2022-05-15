module Main exposing (main)

import Browser
import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (classList)
import Html.Events exposing (on)
import Json.Decode exposing (field, int, maybe)


type alias Model =
    Selection


type Msg
    = Select Selection


type Selection
    = All
    | Box Int
    | Row Int Int
    | Item Int Int Int
    | Clear


main : Program () Model Msg
main =
    Browser.sandbox
        { init = init
        , update = update
        , view = view
        }


init : Model
init =
    Clear


update : Msg -> Model -> Model
update msg _ =
    case msg of
        Select selection ->
            selection


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
box selection boxId =
    div
        [ classList
            [ ( "box", True )
            , ( "selected", selection == Box boxId )
            ]
        ]
        (List.map
            (row selection boxId)
            (List.range 1 3)
        )


row : Selection -> Int -> Int -> Html Msg
row selection boxId rowId =
    div
        [ classList
            [ ( "row", True )
            , ( "selected", selection == Row boxId rowId )
            ]
        ]
        (List.map
            (item selection boxId rowId)
            (List.range 1 3)
        )


item : Selection -> Int -> Int -> Int -> Html Msg
item selection boxId rowId itemId =
    div
        [ onMultiClick (clickMsg boxId rowId itemId)
        , classList
            [ ( "item", True )
            , ( "selected", selection == Item boxId rowId itemId )
            ]
        ]
        []


onMultiClick : (Maybe Int -> msg) -> Attribute msg
onMultiClick intToMsg =
    maybe (field "detail" int)
        |> Json.Decode.map intToMsg
        |> on "click"


clickMsg : Int -> Int -> Int -> Maybe Int -> Msg
clickMsg boxId rowId itemId s =
    case s of
        Just 1 ->
            Select (Item boxId rowId itemId)

        Just 2 ->
            Select (Row boxId rowId)

        Just 3 ->
            Select (Box boxId)

        Just _ ->
            Select All

        Nothing ->
            Select (Item boxId rowId itemId)
