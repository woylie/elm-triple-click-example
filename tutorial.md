# Handling single, double, triple, quadruple clicks in Elm

Elm has `onClick` and `onDoubleClick` event handlers, but what if you need to handle triple, quadruple or any number of clicks?

We're going to build a simple program that displays multiple boxes containing multiple rows containing multiple items. We want different behaviors for different numbers of clicks.

- one click: select one item
- two clicks: select all items in a row
- three clicks: select all items in a box
- four clicks: select all items

This tutorial was written for **Elm 0.18**.

## Initial Setup

Create a file called `Main.elm` and insert the following lines.

```elm
module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode exposing (..)


main =
    Html.beginnerProgram
        { model = initialModel
        , update = update
        , view = view
        }
```

Our model will only contain our current selection. We'll use a union type to define it.

```elm
type Selection
    = All
    | Box Int
    | Row Int Int
    | Item Int Int Int
    | Clear


type alias Model =
    Selection


initialModel : Model
initialModel =
    Clear
```

The first `Int` of `Box`, `Row` and `Item` defines the box, the second `Int` of `Row` and `Item` defines the row, and the last `Int` of `Item` defines the item. We should probably use type aliases to make this clearer:

We're going to define a `Select` message that takes a `Selection` and add an update function to update our model.

```elm
type Msg
    = Select Selection
    | NoOp


update : Msg -> Model -> Model
update msg model =
    case msg of
        Select selection ->
            selection

        NoOp ->
            model
```

To complete our beginnerProgram, we also need a view function.

```elm
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
        [ classList
            [ ( "item", True )
            , ( "selected", selection == Item box row item )
            ]
        ]
        []
```

This will render two boxes with three rows each that in turn contain three items each. Boxes, rows and items are identified by integers. We are using `List.map` and `List.range` to avoid typing it all out.

To add the classes, we're using `Html.Attributes.classList`, which takes a list of tuples with the first element being the class name and the second element being a bool value.

We always want to give boxes, rows and items the class `box`, `row` and `item` respectively, so we just pass True as the second element. But we only want to add the class `selected` if the box, row or item is actually selected, so we check if the current selection matches the current element.

This completes the static version of our program. To compile, run:

```bash
elm make Main.elm --output=main.js
```

## HTML

Create the file `index.html` with the following content.


```html
<!DOCTYPE html>

<html>
  <head>
    <meta charset="utf-8">
    <title>Clickediclick</title>
    <style>
      html, body, #elm, .main {
        height: 100%;
        margin: 0;
      }
      .main {
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;

        display: flex;
        justify-content: space-between;
        align-items: stretch;
      }

      .box {
        flex: 0 1 30%;
        display: flex;
        flex-direction: column;
        justify-content: space-around;
        align-items: stretch;
      }

      .row {
        flex: 0 1 30%;
        display: flex;
        flex-direction: row;
        justify-content: space-around;
        align-items: stretch;
      }

      .row div {
        flex: 0 1 30%;
        background: #00CAF5;
      }

      .selected .item, .item.selected {
        background: #002827;
      }
    </style>
  </head>

  <body>
    <div id="elm"></div>
    <script src="main.js" type="text/javascript"></script>
    <script type="text/javascript">
      Elm.Main.embed(document.querySelector('#elm'));
    </script>
  </body>
</html>
```

This will embed our Elm app and add some styling. If you open the file in a browser, you should nine bland, blue boxes.

## Click Handling

Since Elm doesn't have a function to handle multiple clicks, we'll need to write our own function. We're going to use the `Html.Events.on` function for this. Let's add it to our item attributes.

```elm
item : Selection -> Int -> Int -> Int -> Html Msg
item selection box row item =
    div
        [ on "click" (handleClick box row item)
        , classList
            [ ( "item", True )
            , ( "selected", selection == Item box row item )
            ]
        ]
        []
```

`on` takes the event name as the first argument (in our case `click`) and a `Decoder msg` as the second argument. The `click` event has a whole bunch of [properties](https://developer.mozilla.org/de/docs/Web/Events/click), and we need the JSON decoder to access them. In our application, we're interested in the vaguely named "detail" property, which contains the number of clicks that happened within a short time frame.

Our `handleClick` function will also need the current box, row and item to make a new selection.

```elm
handleClick : Int -> Int -> Int -> Decoder Msg
handleClick box row item =
    maybe (field "detail" int)
        |> andThen (clickMsg box row item)
```

Just in case the browser doesn't support the `detail` property, we're decoding the `detail` field as a `Maybe Int`. This `Maybe Int` will then be passed to `clickMsg`, which will give us a `Msg` depending on the number of clicks.

```elm
    clickMsg : Int -> Int -> Int -> Maybe Int -> Decoder Msg
    clickMsg box row item s =
        Json.Decode.succeed
            (case s of
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
            )
```

In case the browser doesn't pass a proper `detail` property, we want to select a single item only, so we still have some basic functionality. Because `case` needs branches for all possibilities, we need to define a `Just _` branch to handle more than three clicks in a row. We want to select all items in that case, so that all items are being selected even if the user accidentally clicks too often.

Let's compile this again:

```bash
elm make Main.elm --output=main.js
```

Our app should now behave as per spec, but we can clean this up a little bit.

## Cleaning Up

We're going to replace `Json.Decode.andThen` with `Json.Decode.map` first. This will save us the call to `Json.Decode.succeed` and a pair of brackets.

```elm
handleClick : Int -> Int -> Int -> Decoder Msg
handleClick box row item =
    maybe (field "detail" int)
        |> Json.Decode.map (clickMsg box row item)


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
```

That's better, but it's kind of useless to pass `box`, `row` and `item` to our `handleClick` function just to pass it along without doing anything with it. This also makes reusing `handleClick` harder. Let's rename the function to `onMultipleClick` and move the call to `Html.Events.on` from the view to this function.

```elm
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


onMultiClick : (Maybe Int -> msg) -> Attribute msg
onMultiClick intToMsg =
    maybe (field "detail" int)
        |> Json.Decode.map intToMsg
        |> on "click"
```

Now we only need to pass a function with the signature `(Maybe Int -> msg)` to our new `onMultiClick` function. That way, it is not bound to this specific use case and can be reused anywhere. Also note the use of `msg` instead of `Msg` in the type signature. In doing so, we can factor the function out and use it in any package.

You can find the complete code on [Github](https://github.com/woylie/elm-triple-click-example).
