# Cards for TripGo iOS

This is a repo for experimenting with the card-based design for TripGo V5.
Ultimately this might turn into a (private) CocoaPod with the current project
being broken up into a generic part that goes in the pod itself and an example
project for showing how to use it and easily testing all the different cases.

## Specs

### 1. Basic functionality of cards

Behaviour:

- Card positions (!3):
    1. `collapsed`: Only shows header of card
    2. `peaking`: Shows half of card's content and the map content
    3. `extended`: Shows card fully, map shows a little bit on top but is greyed out
- Pushing a card from another card
	- [x] Adds (x) button unless it’s the root card
    - [x] Card has a preferred position which is used when pushing (!3)
	- [x] Animation: Slide up from the bottom; fading black view on card below with alpha from 0% to 25%
	- [x] Pass on appearance callbacks appropriately to involved cards
- Popping a card
	- [x] Tap (x) to pop card
    - [x] When popping top card, restore card position of card below when something got pushed on it (!3)
	- [x] Animation: Slide back down; fading out black view on card below with alpha from 25% to 0%
	- [x] Pass on appearance callbacks appropriately to involved cards
- Cards are draggable
	- [x] Snap to collapsed (only title), peaking (near half-way showing both map and card content), extended (still shows a bit of the map on top, but darkened) (!3)
	- [x] Cards can be dragged up and down anywhere on the card
	- [ ] When scrolling to the top and keeping to scroll, start dragging card
	- [x] Tap title when collapsed: go to peaking (!3)
	- [x] Tap title when peaking: go to extended (!3)
	- [x] Tap title when extended: do nothing
	- [x] Tap map when extended: go to peaking (!3)
- Sticky bar at the top
	- [x] Set content rather than just showing (!1)
	- [x] Cross-fade content if it was showing already and there’s new content (!1)
	- [x] Fix bug: expand card => toggle sticky => card should move down not keep top fixed

Styles:

- [x] Animation curve for push and pop (!1)
- [x] Blurry view under status bar (like Maps app) (!1)
- [x] When rotating device and card is collapsed, make sure card ends up in correct position (!1)

### 2. Card content and gestures

Card types:

- Plain card
	- [x] On top: Title, (x), optional subtitle and optional accessory view
	- [ ] Add accessory view (!11)
	- [x] Content can be scrollable and size adjusts to content. If it fits, it shouldn’t be scrollable
	- [ ] Add floaty button
- Table card
	- [x] Same as plain card, but with a table view as its content
- Paging card (!5)
    - [x] Handles list of child cards on the same hierarchical level which can be paged programatically and through gestures
    - [x] Has header view: Used for titles (child cards shouldn't show them then) and navigation; Header view is separate from sticky bar, i.e., you can have both.
    - [x] Re-uses the top card's map manager
	- [x] Pass on appearance callbacks appropriately to child cards

Card styles:

- [x] Rounded corners to cards (!2)
- [x] Grab handle for cards (!2)
- [x] Nice close buttons (and next button for paging cards) (!5)
- [ ] Title and subtitle styling
- [x] Add mini drop shadow to card views (!2)
- [x] Bottom view (!4)

### 3. Map content

Map content:

- [x] Cards can optionally have map content
- [x] When showing the content, the insets should be respected to account for the card overlapping the map
- [x] If there’s no map content: Show card always extended and don't allow dragging it down (or just snap back up when using tries) (!3)

Map widget:

- [ ] Optional widget such as a search bar or the from/to/at widget that floats on top of the map (!10)
- [ ] Map content properly considers that the widget is there (map content and map controls such as the compass) (!10)
- [ ] When dragging up the card the widget scrolls away to the top (!10)

Map buttons:

- [ ] Optional list of buttons that float on the right above the card (when collapsed or peaking)

### 4. Large screens (iPad + iPhone Plus in landscape)

- [x] Move card to the side with min (iPhone Plus) and max (iPad) width (!9)
- [x] Make sure transitions work when changing size and traits (!9)
