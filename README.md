<p align="center">
<img src="https://raw.githubusercontent.com/adrianflutur/flutter_improved_scrolling/main/doc/media/logo.png" width="640" alt="improved_scrolling" />
</p>

[![pub package](https://shields.io/pub/v/flutter_improved_scrolling.svg?style=flat-square&color=blue)](https://pub.dev/packages/flutter_improved_scrolling)

### An attempt to implement better scrolling for Flutter Web and Desktop.

### Includes keyboard, MButton and custom mouse wheel scrolling.

<br>

## _**Getting started**_

- [Example](#example)
- [Usage and features](#usage-and-features)
- [License](#license)

<br>

## _**Example**_

<br>

<img src="https://raw.githubusercontent.com/adrianflutur/flutter_improved_scrolling/main/doc/media/improved_scrolling_example.gif" width="1280"/>

<br><br>

## _**Usage and features**_

(from the [example app](https://github.com/adrianflutur/flutter_improved_scrolling/tree/main/example/lib/scrollable_page.dart))

```dart
final controller = ScrollController();

...

ImprovedScrolling(
      scrollController: controller,
      onScroll: (scrollOffset) => debugPrint(
        'Scroll offset: $scrollOffset',
      ),
      onMMBScrollStateChanged: (scrolling) => debugPrint(
        'Is scrolling: $scrolling',
      ),
      onMMBScrollCursorPositionUpdate: (localCursorOffset, scrollActivity) => debugPrint(
            'Cursor position: $localCursorOffset\n'
            'Scroll activity: $scrollActivity',
      ),
      enableMMBScrolling: true,
      enableKeyboardScrolling: true,
      enableCustomMouseWheelScrolling: true,
      mmbScrollConfig: MMBScrollConfig(
        customScrollCursor: useSystemCursor ? null : const DefaultCustomScrollCursor(),
      ),
      keyboardScrollConfig: KeyboardScrollConfig(
        arrowsScrollAmount: 250.0,
        homeScrollDurationBuilder: (currentScrollOffset, minScrollOffset) {
          return const Duration(milliseconds: 100);
        },
        endScrollDurationBuilder: (currentScrollOffset, maxScrollOffset) {
          return const Duration(milliseconds: 2000);
        },
      ),
      customMouseWheelScrollConfig: const CustomMouseWheelScrollConfig(
        scrollAmountMultiplier: 2.0,
      ),
      child: ScrollConfiguration(
        behavior: const CustomScrollBehaviour(),
        child: GridView(
          controller: controller,
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: axis,
          padding: const EdgeInsets.all(24.0),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400.0,
            mainAxisExtent: 400.0,
          ),
          children: buildScrollableItemList(axis),
        ),
      ),
    );
```

<br>

### Requirements

- The `ImprovedScrolling` Widget must be added as a parent of your scrollable Widget (`List/Grid/SingleChildScrollView/etc`).
- You must create and provide the same scroll controller to both the `ImprovedScrolling` Widget and your scrollable Widget.

* _Optional_: If you want to programatically scroll when rotating the mouse wheel and not let the framework manage the scrolling, you can set `physics: NeverScrollableScrollPhysics()` to your scrollable and then set `enableCustomMouseWheelScrolling: true` on `ImprovedScrolling` to enable this feature.

<br>

### Features:

- #### Scrolling using the keyboard (Arrows, Page{Up, Down}, Spacebar, Home, End)

  > You need to set `enableKeyboardScrolling: true` and then you can configure the scrolling amount, duration and curve by using `keyboardScrollConfig: KeyboardScrollConfig(...)`

- #### Scrolling using the middle mouse button ("auto-scrolling")

  > You need to set `enableMMBScrolling: true` and then you can configure the scrolling delay, velocity, acceleration and cursor appearance and size by using `mmbScrollConfig: MMBScrollConfig(...)`  
  > <br>
  >
  > There is also a `DefaultCustomScrollCursor` class which is a default custom cursor implementation

- #### Programatically scroll using the mouse wheel

  > You need to set `enableCustomMouseWheelScrolling: true` and then you can configure the scrolling speed, duration, curve and throttling time by using `customMouseWheelScrollConfig: CustomMouseWheelScrollConfig(...)`

- #### Horizontal scrolling using Left/Right arrows or Shift + mouse wheel

  > Requires `enableKeyboardScrolling: true` and `enableCustomMouseWheelScrolling: true` to be set.

<br>

### Callbacks:

#### Other than the above features, there are also a few callbacks available on the `ImprovedScrolling` Widget:

<br>

```dart
// Triggers whenever the ScrollController scrolls, no matter how or why
onScroll: (double scrollOffset) => debugPrint(
  'Scroll offset: $scrollOffset',
),

// Triggers whenever the middle mouse button scrolling feature is activated or deactivated
onMMBScrollStateChanged: (bool scrolling) => debugPrint(
  'Is scrolling: $scrolling',
),

// Triggers whenever the cursor is moved on the scrollable area, while the
// middle mouse button feature is active and is scrolling
//
// We also get the current scroll activity (idle or moving up/down/left/right)
// at the time the cursor moves
onMMBScrollCursorPositionUpdate: (
  Offset localCursorOffset,
  MMBScrollCursorActivity scrollActivity,
) => debugPrint(
    'Cursor position: $localCursorOffset\n'
    'Scroll activity: $scrollActivity',
 ),
```

## _**License**_

[MIT](https://github.com/adrianflutur/flutter_improved_scrolling/blob/main/LICENSE)
