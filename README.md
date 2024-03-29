# TGCardViewController

[![CI](https://github.com/skedgo/TGCardViewController/actions/workflows/swift.yml/badge.svg)](https://github.com/skedgo/TGCardViewController/actions/workflows/swift.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fskedgo%2FTGCardViewController%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/skedgo/TGCardViewController)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fskedgo%2FTGCardViewController%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/skedgo/TGCardViewController)

Provides a card-based view controller for mapping applications where the card's content is in sync with a map, similar to how Apple Maps works. For an application of this see the [TripKitUI SDK](https://github.com/skedgo/tripkit-ios) and [TripGo](https://apps.apple.com/au/app/tripgo/id533630842) by [SkedGo](https://skedgo.com).

<img src="Docs/collapsed.png" alt="Collapsed" width="213" height="379" align="left" />

<img src="Docs/peaking.png" alt="Peaking" width="213" height="379" align="left" />

<img src="Docs/expanded.png" alt="Expanded" width="213" height="379" align="left" />

<img src="Docs/custom_header.png" alt="Custom header" width="213" height="379" />

<hr/>

## Installation and usage

### Install

<details>
<summary>Via Swift Package Manager (recommended)</summary>

1. Add it to your `Package.swift` file (or add it as a dependency through Xcode):

```swift
.package(url: "https://github.com/skedgo/TGCardViewController.git", from: "1.7.5")
```

</details>

<details>
<summary>Via CocoaPods</summary>

1. Check out the repo and make it accessible to your project, e.g., as a git submodule
2. Add it to your `Podfile`, e.g.:

	`pod 'TGCardViewController`

3. Run `pod update`

</details>
	
### Add it to your app

1. Create a `TGCardViewController` subclass and use it in your storyboard
2. Override `init(coder:)` so that the instance from the storyboard isn't used, but instead `TGCardViewController.xib`:

    ```swift
    import TGCardViewController
    
    class CardViewController: TGCardViewController {

      required init(coder aDecoder: NSCoder) {
        // When loading from the storyboard we don't want to use the controller
        // as defined in the storyboard but instead use the TGCardViewController.xib
        super.init(nibName: "TGCardViewController", bundle: TGCardViewController.bundle)
      }

      ...
    }
    ```

3. Create a `TGCard` subclass, that represents the card at the top level, and add then push that in your view controller's `viewDidLoad`:

    ```swift
      override func viewDidLoad() {
        rootCard = MyRootCard()
        super.viewDidLoad()
      }
    ```

## Specs

### 1. Basic functionality of cards

Behaviour:

- Card positions:
    1. `collapsed`: Only shows header of card
    2. `peaking`: Shows half of card's content and the map content
    3. `extended`: Shows card fully, map shows a little bit on top but is greyed out
- Pushing a card from another card
	- [x] Adds (x) button unless it’s the root card
    - [x] Card has a preferred position which is used when pushing
	- [x] Animation: Slide up from the bottom; fading black view on card below with alpha from 0% to 25%
	- [x] Pass on appearance callbacks appropriately to involved cards
- Popping a card
	- [x] Tap (x) to pop card
    - [x] When popping top card, restore card position of card below when something got pushed on it
	- [x] Animation: Slide back down; fading out black view on card below with alpha from 25% to 0%
	- [x] Pass on appearance callbacks appropriately to involved cards
- Cards are draggable
	- [x] Snap to collapsed (only title), peaking (near half-way showing both map and card content), extended (still shows a bit of the map on top, but darkened)
	- [x] Cards can be dragged up and down anywhere on the card
	- [x] Tap title when collapsed: go to peaking
	- [x] Tap title when peaking: go to extended
	- [x] Tap title when extended: do nothing
	- [x] Tap map when extended: go to peaking
- Cards are scrollable
    - [x] Cards typically have scrolling content: when scrolling down the card's header stays at the top and a  bit of the map still keeps peaking through at the top.
	- [x] When scrolling down show a thin separator line between the card's scrolling content and the card's header
	- [x] When scrolling to the top and keeping to scroll, start dragging card

Styles:

- [x] Animation curve for push and pop
- [x] Blurry view under status bar (like Maps app)
- [x] When rotating device and card is collapsed, make sure card ends up in correct position

### 2. Card content and gestures

Card types:

- Plain card
	- [x] On top: Title, (x), optional subtitle and optional accessory view
	- [x] Add accessory view
	- [x] Content can be scrollable and size adjusts to content. If it fits, it shouldn’t be scrollable
	- [x] Add optional floaty button
- Table card
	- [x] Same as plain card, but with a table view as its content
	- [x] Allow specifying plain (e.g., for departures) or grouped style (e.g., for profile)
- Collection card
  - [x] Same as plain card, but with a collection view as its content
  - [x] Allow specifying collection view layout
- Hosting card
  - [x] Allow using a SwiftUI view as the card's content
- Paging card
    - [x] Handles list of child cards on the same hierarchical level which can be paged programatically and through gestures
    - [x] Has header view: Used for titles (child cards shouldn't show them then) and navigation; Header view is separate from sticky bar, i.e., you can have both.
    - [x] Re-uses the top card's map manager
	- [x] Pass on appearance callbacks appropriately to child cards

Card styles:

- [x] Rounded corners to cards
- [x] Grab handle for cards
- [x] Nice close buttons (and next button for paging cards)
- [x] Title and subtitle styling
- [x] Add mini drop shadow to card views
- [x] Bottom view

### 3. Map content

Map content:

- [x] Cards can optionally have map content
- [x] When showing the content, the insets should be respected to account for the card overlapping the map
- [x] If there’s no map content: Show card always extended and don't allow dragging it down (or just snap back up when using tries)

Map buttons:

- [x] Optional list of buttons that float on the right above the card or in the top right corner (when collapsed or peaking)
- [x] When dragging up the card to `extended`, the buttons fade away

### 4. Large width (iPad + iPhone in landscape)

- [x] Move card to the side with min (iPhone Plus) and max (iPad) width
- [x] Make sure transitions work when changing size and traits
 
### 5. UIKit features

- [x] State restoration, using `NSUserActivity`
- [x] VoiceOver Accessibility
- [x] Keyboard shortcuts


## End-user documentation

### Keyboard shortcuts

- Card controller
  - ⌃+↑: Expand card
  - ⌃+↓: Expand/collapse card
  - ⌘+w: Pop card or dismiss modal
- Table view cards
  - ↑: Highlight previous item
  - ↓: Highlight next item
  - ⌘+↑: Highlight item at start of list
  - ⌘+↓: Highlight item at end of list
  - Space or enter: select item
  - Esc: deselect
- Paging cards
  - ⌃+←: Previous card 
  - ⌃+→: Next card
