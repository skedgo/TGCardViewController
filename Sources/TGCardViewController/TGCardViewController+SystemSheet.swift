//
//  TGCardViewController+SystemSheet.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/10/2026.
//  Copyright © 2026 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

extension TGCardViewController {

  /// How a ``TGCardViewController`` presents its cards.
  public enum PresentationStyle {

    /// Uses ``systemSheet`` where it's a good fit, and ``classic`` otherwise.
    ///
    /// System sheets are used on iOS 26 and later, in ``Mode-swift.enum/floating``
    /// mode, in compact width and regular height (i.e., an iPhone in portrait or a
    /// narrow iPad window), and only when the card controller isn't itself presented
    /// in a sheet.
    case automatic

    /// The card controller positions the cards itself, and they're dragged using
    /// its own gestures.
    case classic

    /// Cards are shown in a system sheet (`UISheetPresentationController`) whenever
    /// the size classes allow it (compact width and regular height), and in
    /// ``Mode-swift.enum/floating`` mode. Falls back to ``classic`` otherwise.
    case systemSheet
  }

  /// Whether the cards are currently shown in a system sheet.
  ///
  /// This can change during the lifetime of the controller, e.g., when rotating
  /// the device. See ``presentationStyle``.
  public var usesSystemSheet: Bool {
    sheetHost != nil
  }

  /// The view controller that's presented on top of the cards, if any.
  ///
  /// Use this instead of `presentedViewController` to check if something covers
  /// the cards: when the cards are shown in a system sheet, the sheet itself is
  /// the `presentedViewController` of this controller.
  public var presentedOverlayViewController: UIViewController? {
    if let sheetHost, presentedViewController === sheetHost {
      return sheetHost.presentedViewController
    } else {
      return presentedViewController
    }
  }

  /// The view that contains the cards' views.
  ///
  /// Use this if you need to add views that are positioned relative to views of a
  /// card. When the cards are shown in a system sheet, this is the sheet's view;
  /// otherwise it's this controller's `view`.
  public var cardOverlayView: UIView {
    sheetHost?.view ?? view
  }

}

// MARK: - Deciding when to use a sheet

extension TGCardViewController {

  func wantsSystemSheet(for traits: UITraitCollection) -> Bool {
#if targetEnvironment(macCatalyst) || os(visionOS)
    return false
#else
    guard mode == .floating else { return false }

    switch presentationStyle {
    case .classic:
      return false
    case .automatic:
      guard #available(iOS 26.0, *) else { return false }
    case .systemSheet:
      break
    }

    guard
      traits.horizontalSizeClass == .compact,
      traits.verticalSizeClass == .regular
    else { return false }

    // Don't show a sheet from a sheet. Being presented full screen is fine.
    let outermost = sequence(first: self as UIViewController, next: \.parent).reduce(self as UIViewController) { $1 }
    if outermost.presentingViewController != nil,
       ![.fullScreen, .overFullScreen].contains(outermost.modalPresentationStyle) {
      return false
    }

    return true
#endif
  }

  /// Installs or removes the system sheet, as appropriate for the current state.
  ///
  /// Safe to call often: it does nothing if the sheet is already in the right state,
  /// and it defers changes it can't make yet, e.g., while something is presented.
  func updateSystemSheetPresentation() {
    guard isViewLoaded else { return }

    let wantsSheet = wantsSystemSheet(for: traitCollection) && topCardView != nil
    if wantsSheet, sheetHost == nil {
      installSystemSheet()
    } else if !wantsSheet, sheetHost != nil {
      uninstallSystemSheet(animated: topCardView == nil && isVisible)
    } else if !wantsSheet, isAwaitingSystemSheet {
      revealClassicCards()
    }
  }

  private func revealClassicCards() {
    guard isAwaitingSystemSheet else { return }
    isAwaitingSystemSheet = false
    toggleCardWrappers(hide: topCardView == nil)
  }

}

// MARK: - Installing and removing the sheet

extension TGCardViewController {

  private func installSystemSheet() {
    guard
      isVisible,
      view.window != nil,
      presentedViewController == nil,
      transitionCoordinator == nil,
      let content = cardWrapperContent
    else {
      // We'll try again later, e.g., after the presented view controller got
      // dismissed. Until then, show the cards in the classic way, as we don't
      // know when that'll be.
      revealClassicCards()
      return
    }

    let position = cardPosition

    let host = TGSheetHostViewController(cardController: self)
    host.loadViewIfNeeded()
    syncSheetHostAppearance(host)

    // 1. Move the cards into the sheet. The card wrapper stays where it is, but
    //    invisible, and it'll mirror the top edge of the sheet. That way all the
    //    map buttons, the header and the map's insets keep working as before.
    savedCardContentConstraints = cardWrapperShadow.constraints.filter {
      $0.firstItem === content || $0.secondItem === content
    }
    content.removeFromSuperview()
    host.view.addSubview(content)
    content.translatesAutoresizingMaskIntoConstraints = false

    // The cards keep the height they'd have when extended, and the sheet clips
    // them, rather than relaying them out whenever the sheet changes its height.
    let heightConstraint = content.heightAnchor.constraint(equalToConstant: estimatedSheetContentHeight(in: host))
    NSLayoutConstraint.activate([
      content.topAnchor.constraint(equalTo: host.view.topAnchor),
      content.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
      content.trailingAnchor.constraint(equalTo: host.view.trailingAnchor),
      heightConstraint,
    ])
    sheetContentHeightConstraint = heightConstraint

    // 2. Configure the sheet
    sheetHost = host
    isAwaitingSystemSheet = false

    if let sheet = host.sheetPresentationController {
      sheet.delegate = host
      sheet.prefersScrollingExpandsWhenScrolledToEdge = true
      sheet.prefersEdgeAttachedInCompactHeight = true
      sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = false
      sheetTargetPosition = position
      applySheetConfiguration(to: sheet, selecting: position)
    }

    // 3. Hand over the chrome
    updateCardChromeForPresentationStyle()
    updateForNewPosition(position: position)
    updateSheetContentScrollView()

    super.present(host, animated: false)
  }

  /// Moves the cards back into this controller's view and removes the sheet.
  ///
  /// If something's presented on top of the sheet, this does nothing. Call
  /// ``updateSystemSheetPresentation()`` again once that's gone.
  func uninstallSystemSheet(animated: Bool) {
    guard let host = sheetHost, host.presentedViewController == nil else { return }

    let position = cardPosition
    sheetHost = nil
    sheetTargetPosition = nil
    sheetDetentValues = [:]
    updateSheetBarItems()

    let moveCardsBack = { [self] in
      guard let content = cardWrapperContent else { return assertionFailure() }

      content.removeFromSuperview()
      cardWrapperShadow.insertSubview(content, aboveSubview: cardWrapperEffectView)
      NSLayoutConstraint.activate(savedCardContentConstraints)
      savedCardContentConstraints = []
      sheetContentHeightConstraint = nil

      updateCardChromeForPresentationStyle()
    }

    host.allowsDismissingSheet = true
    if host.isBeingDismissed {
      // E.g., when we're dismissed ourselves, which takes the sheet along
      moveCardsBack()
    } else if animated {
      super.dismiss(animated: true, completion: moveCardsBack)
    } else {
      moveCardsBack()
      super.dismiss(animated: false)
    }

    // Put the card where the sheet was
    let location = cardLocation(forDesired: position, direction: .up)
    mapViewController.additionalSafeAreaInsets = updateCardPosition(y: location.y)
    view.setNeedsUpdateConstraints()
    updateCardScrolling(allow: location.position == .extended, view: topCardView)
    updateMapShadow(for: location.position)
    updateForNewPosition(position: location.position)
  }

  /// Gestures, effects, grab handles and corners differ between the classic
  /// presentation and the sheet.
  private func updateCardChromeForPresentationStyle() {
    let inSheet = usesSystemSheet

    // The sheet provides the material, so the card wrapper is a placeholder
    if inSheet {
      if savedCardWrapperEffect == nil {
        savedCardWrapperEffect = cardWrapperEffectView.effect
      }
      cardWrapperEffectView.effect = nil
    } else if let effect = savedCardWrapperEffect {
      cardWrapperEffectView.effect = effect
      savedCardWrapperEffect = nil
    }
    cardWrapperShadow.isUserInteractionEnabled = !inSheet
    toggleCardWrappers(hide: topCardView == nil)

    // The sheet does the dragging
    mapShadowTapper.isEnabled = !inSheet && mode == .floating
    if inSheet {
      panner.isEnabled = false
    } else {
      updatePannerInteractivity()
      if !isSheetDraggingEnabled {
        panner.isEnabled = false
      }
    }

#if !os(visionOS)
    // Popping by swiping from the edge should also work on the sheet, not just
    // on the map. The sheet's recognizer goes away with the sheet.
    if let sheetView = sheetHost?.view, !(sheetView.gestureRecognizers ?? []).contains(where: { $0 is UIScreenEdgePanGestureRecognizer }) {
      let sheetEdgePanner = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(popMaybe))
      sheetEdgePanner.edges = edgePanner.edges
      sheetEdgePanner.isEnabled = edgePanner.isEnabled
      sheetView.addGestureRecognizer(sheetEdgePanner)
    }
#endif

    updateMapShadow(for: inSheet ? .collapsed : cardPosition)
    updateGrabHandleVisibility()
    updateCardScrolling(allow: inSheet || cardPosition == .extended, view: topCardView)

    for cardView in cards.compactMap(\.view) {
      applyCorners(to: cardView)
      cardView.adjustContentAlpha(to: contentAlpha(for: cardPosition))
    }

    // Card-attached floating views need to be next to the card
    if cardFloatingView.superview != nil {
      cardFloatingView.removeFromSuperview()
      updateCardFloatingViewContent(card: topCard)
    }

    view.setNeedsLayout()
  }

  func applyCorners(to cardView: TGCardView) {
    guard #available(iOS 26.0, visionOS 26.0, *) else { return }
    
    if usesSystemSheet {
      // The sheet rounds and clips its content
      cardView.cornerConfiguration = .corners(radius: .fixed(0))
      cardView.clipsToBounds = false
    } else if mode == .floating {
      // Match the corners of the glass behind the card, so that cards with a
      // non-clear background don't stick out at the corners
      cardView.cornerConfiguration = cardWrapperEffectView.cornerConfiguration
      cardView.clipsToBounds = true
    }
  }
  
  /// The classic card hides everything but its title when collapsed, as the rest
  /// would show below the screen's safe area. The sheet clips that itself.
  func contentAlpha(for position: TGCardPosition) -> CGFloat {
    usesSystemSheet || position != .collapsed ? 1 : 0
  }
  
  func forcesSeparatorHidden(for position: TGCardPosition) -> Bool {
    !usesSystemSheet && position == .collapsed
  }
  
  /// The view that card transitions add their temporary views to
  var cardTransitionContainer: UIView? {
    usesSystemSheet ? cardWrapperContent.superview : cardWrapperShadow.superview
  }
  
  /// The view that card transitions add their temporary views next to
  var cardTransitionAnchor: UIView {
    usesSystemSheet ? cardWrapperContent : cardWrapperShadow
  }

  private func syncSheetHostAppearance(_ host: TGSheetHostViewController) {
    if host.view.tintColor != view.tintColor {
      host.view.tintColor = view.tintColor
    }
    if host.overrideUserInterfaceStyle != overrideUserInterfaceStyle {
      host.overrideUserInterfaceStyle = overrideUserInterfaceStyle
    }
  }

  /// Tells the sheet which scroll view to track for scrolling vs. resizing.
  func updateSheetContentScrollView() {
    sheetHost?.setContentScrollView(topCardView?.contentScrollView)
    updateSheetBarItems()
  }

}

// MARK: - Bar items next to a vertical bar

extension TGCardViewController {
  
  /// On devices with a vertical bar, e.g., the iPhone Duo's outer display, the
  /// system puts a sheet's close button and its navigation bar's items into
  /// that bar. Cards have their close buttons in their titles, which end up
  /// under the status bar when the sheet is at full height. So while the cards
  /// are in a system sheet next to a vertical bar, this hides the close buttons
  /// in the top card's titles, and shows a stand-in in the bar, below the
  /// status bar, which forwards taps to the card's own. The top card's
  /// `barActions` follow below it.
  ///
  /// The items stay in the bar at every height of the sheet. One copy of them
  /// is over the map, and another one on the sheet, where the sheet covers the
  /// bar; see `syncSheetBarItems(sheetTop:)`.
  func updateSheetBarItems() {
    guard #available(iOS 27.1, *) else { return }
    
    let barEdge = sheetHost?.traitCollection.verticalBarEdge ?? .unspecified
    let showsBar = sheetHost != nil && barEdge != .unspecified
    updateShowsBarActions(showsBar)
    
    let closeButtons: [UIButton]
    let currentCloseButton: UIButton?
    let actions: [UIAction]
    let paging: TGBarItemsView.Paging?
    if let pageCard = topCard as? TGPageCard {
      // Hide them on all pages, so they don't show up while paging
      closeButtons = pageCard.cards.compactMap { $0.cardView?.dismissButton }
      currentCloseButton = pageCard.currentCard.cardView?.dismissButton
      actions = pageCard.barActions + pageCard.currentCard.barActions
      let index = pageCard.currentPageIndex
      paging = pageCard.cards.count > 1
        ? .init(hasPrevious: index > 0, hasNext: index < pageCard.cards.count - 1)
        : nil
    } else {
      currentCloseButton = topCardView?.dismissButton
      closeButtons = [currentCloseButton].compactMap { $0 }
      actions = topCard?.barActions ?? []
      paging = nil
    }
    
    guard
      showsBar,
      let host = sheetHost,
      currentCloseButton != nil || paging != nil || !actions.isEmpty
    else {
      suppressedCloseButtons.forEach { Self.setCloseButton($0, suppressed: false) }
      suppressedCloseButtons = []
      mapBarItems?.removeFromSuperview()
      mapBarItems = nil
      sheetBarItems?.removeFromSuperview()
      sheetBarItems = nil
      barItemsEdge = nil
      return
    }
    
    // Swap which buttons are hidden in the titles
    for button in suppressedCloseButtons where !closeButtons.contains(button) {
      Self.setCloseButton(button, suppressed: false)
    }
    closeButtons.forEach { Self.setCloseButton($0, suppressed: true) }
    suppressedCloseButtons = closeButtons
    
    let edge: NSDirectionalRectEdge = barEdge == .leading ? .leading : .trailing
    let mapItems: TGBarItemsView
    let sheetItems: TGBarItemsView
    if let existingMap = mapBarItems, let existingSheet = sheetBarItems, barItemsEdge == edge, existingMap.superview === view, existingSheet.superview === host.view {
      mapItems = existingMap
      sheetItems = existingSheet
    } else {
      mapBarItems?.removeFromSuperview()
      sheetBarItems?.removeFromSuperview()
      
      // In the bar along the edge of the screen, below the status bar
      mapItems = makeBarItemsView()
      mapItems.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(mapItems)
      let guide = view.layoutGuide(for: .bar(onEdge: edge, extent: TGBarItemsView.itemSize))
      NSLayoutConstraint.activate([
        mapItems.topAnchor.constraint(equalTo: guide.topAnchor),
        mapItems.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
        mapItems.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
        mapItems.widthAnchor.constraint(equalToConstant: TGBarItemsView.itemSize),
      ])
      
      // Positioned to match `mapItems` whenever the sheet lays out
      sheetItems = makeBarItemsView()
      host.view.addSubview(sheetItems)
      
      mapBarItems = mapItems
      sheetBarItems = sheetItems
      barItemsEdge = edge
    }
    
    let style = topCard?.style ?? .default
    mapItems.update(closeButtonLike: currentCloseButton, style: style, paging: paging, actions: actions)
    sheetItems.update(closeButtonLike: currentCloseButton, style: style, paging: paging, actions: actions)
    view.bringSubviewToFront(mapItems)
    host.view.bringSubviewToFront(sheetItems)
    
    view.layoutIfNeeded()
    syncSheetBarItems(sheetTop: host.view.convert(host.view.bounds, to: view).minY)
  }
  
  /// Puts the sheet's copy of the bar items where the map's are, and shows
  /// each item on whichever of the two is in front of the bar at its position:
  /// the map above the sheet's top, the sheet below it. The sheet's copy gets
  /// clipped by the sheet. Called whenever the sheet lays out, including while
  /// it's being dragged.
  ///
  /// - Parameter sheetTop: The top of the sheet in this controller's view
  func syncSheetBarItems(sheetTop: CGFloat) {
    guard
      let mapItems = mapBarItems,
      let sheetItems = sheetBarItems,
      let host = sheetHost
    else { return }
    
    let frame = host.view.convert(mapItems.frame, from: view)
    if sheetItems.frame != frame {
      sheetItems.frame = frame
    }
    sheetItems.layoutIfNeeded()
    
    // Groups fade as a whole, so they don't get cut in half
    for (mapGroup, sheetGroup) in zip(mapItems.groups, sheetItems.groups) {
      let groupFrame = mapGroup.convert(mapGroup.bounds, to: view)
      mapGroup.alpha = groupFrame.minY < sheetTop ? 1 : 0
      sheetGroup.alpha = groupFrame.maxY > sheetTop ? 1 : 0
    }
    
    // Buttons are tappable where they're mostly visible
    for (mapButton, sheetButton) in zip(mapItems.buttons, sheetItems.buttons) {
      let buttonFrame = mapButton.convert(mapButton.bounds, to: view)
      let mapOwnsButton = buttonFrame.midY < sheetTop
      mapButton.isUserInteractionEnabled = mapOwnsButton
      mapButton.accessibilityElementsHidden = !mapOwnsButton
      sheetButton.isUserInteractionEnabled = !mapOwnsButton
      sheetButton.accessibilityElementsHidden = mapOwnsButton
    }
  }
  
  private func makeBarItemsView() -> TGBarItemsView {
    TGBarItemsView { [weak self] in
      self?.forwardBarCloseButtonTap()
    } onPage: { [weak self] forward in
      guard let pageCard = self?.topCard as? TGPageCard else { return }
      if forward {
        pageCard.moveForward()
      } else {
        pageCard.moveBackward()
      }
    }
  }
  
  /// Tells the cards in the stack whether bar actions are shown, so that they
  /// can leave them out of their content.
  private func updateShowsBarActions(_ shows: Bool) {
    for card in cards.map(\.card) {
      let pages = (card as? TGPageCard)?.cards ?? []
      for card in [card] + pages where card.showsBarActions != shows {
        card.showsBarActions = shows
      }
    }
  }
  
  private func forwardBarCloseButtonTap() {
    let closeButton: UIButton?
    if let pageCard = topCard as? TGPageCard {
      closeButton = pageCard.currentCard.cardView?.dismissButton
    } else {
      closeButton = topCardView?.dismissButton
    }
    closeButton?.sendActions(for: .touchUpInside)
  }
  
  /// Hides a close button in a card's title, without changing its layout, nor
  /// its `isHidden`, which says whether the card should have a close button.
  private static func setCloseButton(_ button: UIButton, suppressed: Bool) {
    button.alpha = suppressed ? 0 : 1
    button.isUserInteractionEnabled = !suppressed
    button.accessibilityElementsHidden = suppressed
  }
  
}

/// A card's items in a vertical bar, like the system's for a navigation bar:
/// the close button and, for paging cards, buttons for the previous and next
/// page at the top, and the bar actions at the bottom, all icon-only.
final class TGBarItemsView: UIView {
  
  struct Paging {
    var hasPrevious: Bool
    var hasNext: Bool
  }
  
  /// The size of each item, and the width of the bar region they're centred
  /// in, which matches the system's close buttons
  static let itemSize: CGFloat = 44
  
  /// The size that icons of bar actions get scaled to fit in, unless they're
  /// symbol images
  private static let iconSize: CGFloat = 20
  
  init(onClose: @escaping () -> Void, onPage: @escaping (_ forward: Bool) -> Void) {
    closeButton = Self.makeButton()
    closeSlot = UIView()
    previousButton = Self.makeButton()
    nextButton = Self.makeButton()
    pagingGroup = Self.makeGroup(with: [previousButton, nextButton])
    actionsStack = Self.makeStack()
    actionsGroup = Self.makeGroup(with: actionsStack)
    super.init(frame: .zero)
    
    closeButton.addAction(UIAction { _ in onClose() }, for: .touchUpInside)
    previousButton.addAction(UIAction { _ in onPage(false) }, for: .primaryActionTriggered)
    nextButton.addAction(UIAction { _ in onPage(true) }, for: .primaryActionTriggered)
    previousButton.accessibilityLabel = NSLocalizedString("Previous card", bundle: TGCardViewController.bundle, comment: "")
    nextButton.accessibilityLabel = NSLocalizedString("Next card", bundle: TGCardViewController.bundle, comment: "")
    
    // The slot keeps its space when a page has no close button, so that the
    // paging buttons don't move around while paging
    closeSlot.translatesAutoresizingMaskIntoConstraints = false
    closeSlot.addSubview(closeButton)
    NSLayoutConstraint.activate([
      closeButton.topAnchor.constraint(equalTo: closeSlot.topAnchor),
      closeButton.bottomAnchor.constraint(equalTo: closeSlot.bottomAnchor),
      closeButton.leadingAnchor.constraint(equalTo: closeSlot.leadingAnchor),
      closeButton.trailingAnchor.constraint(equalTo: closeSlot.trailingAnchor),
    ])
    
    let topStack = UIStackView(arrangedSubviews: [closeSlot, pagingGroup])
    topStack.axis = .vertical
    topStack.alignment = .center
    topStack.spacing = 8
    topStack.translatesAutoresizingMaskIntoConstraints = false
    addSubview(topStack)
    addSubview(actionsGroup)
    
    NSLayoutConstraint.activate([
      topStack.topAnchor.constraint(equalTo: topAnchor),
      topStack.centerXAnchor.constraint(equalTo: centerXAnchor),
      actionsGroup.bottomAnchor.constraint(equalTo: bottomAnchor),
      actionsGroup.centerXAnchor.constraint(equalTo: centerXAnchor),
    ])
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private let closeButton: UIButton
  private let closeSlot: UIView
  private let previousButton: UIButton
  private let nextButton: UIButton
  private let pagingGroup: UIView
  private let actionsStack: UIStackView
  private let actionsGroup: UIView
  private var actionButtons: [UIButton] = []
  private var actions: [UIAction] = []
  
  /// The items that show or hide as a whole, from top to bottom
  var groups: [UIView] {
    [closeSlot, pagingGroup, actionsGroup]
  }
  
  /// All buttons from top to bottom, including hidden ones
  var buttons: [UIButton] {
    [closeButton, previousButton, nextButton] + actionButtons
  }
  
  /// Lets touches through, except on the items
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let hit = super.hitTest(point, with: event)
    return hit === self ? nil : hit
  }
  
  /// - Parameters:
  ///   - source: The card's close button that `closeButton` stands in for
  ///   - style: The card's style
  ///   - paging: Where a page card is at, if the card is paging
  ///   - actions: The bar actions
  @available(iOS 26.0, *)
  func update(closeButtonLike source: UIButton?, style: TGCardStyle, paging: Paging?, actions: [UIAction]) {
    TGCard.configureCloseButton(closeButton, style: style)
    closeButton.accessibilityLabel = source?.accessibilityLabel
      ?? NSLocalizedString("Close card", bundle: TGCardViewController.bundle, comment: "")
    closeButton.isSpringLoaded = source?.isSpringLoaded ?? false
    closeButton.isHidden = source?.isHidden ?? true
    closeSlot.isHidden = closeButton.isHidden && paging == nil
    
    pagingGroup.isHidden = paging == nil
    Self.configure(previousButton, image: UIImage(systemName: "chevron.left"))
    Self.configure(nextButton, image: UIImage(systemName: "chevron.right"))
    previousButton.isEnabled = paging?.hasPrevious ?? false
    nextButton.isEnabled = paging?.hasNext ?? false
    
    // Reuse the action buttons, which perform whichever action is at their
    // index, so that updating an action doesn't flicker.
    self.actions = actions
    actionsGroup.isHidden = actions.isEmpty
    while actionButtons.count < actions.count {
      let index = actionButtons.count
      let button = Self.makeButton()
      button.addAction(UIAction { [weak self, weak button] _ in
        guard let self, let button, index < self.actions.count else { return }
        button.sendAction(self.actions[index])
      }, for: .primaryActionTriggered)
      actionsStack.addArrangedSubview(button)
      actionButtons.append(button)
    }
    while actionButtons.count > actions.count {
      actionButtons.removeLast().removeFromSuperview()
    }
    for (button, action) in zip(actionButtons, actions) {
      Self.configure(button, image: Self.icon(action.image), isDestructive: action.attributes.contains(.destructive))
      button.accessibilityLabel = action.title
      button.isEnabled = !action.attributes.contains(.disabled)
      button.isSelected = action.state == .on
    }
  }
  
  private static func makeButton() -> UIButton {
    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      button.widthAnchor.constraint(equalToConstant: itemSize),
      button.heightAnchor.constraint(equalToConstant: itemSize),
    ])
    return button
  }
  
  private static func makeStack(with buttons: [UIButton] = []) -> UIStackView {
    let stack = UIStackView(arrangedSubviews: buttons)
    stack.axis = .vertical
    stack.alignment = .center
    return stack
  }
  
  private static func makeGroup(with buttons: [UIButton]) -> UIView {
    makeGroup(with: makeStack(with: buttons))
  }
  
  /// Buttons sharing one capsule, like the system groups bar items
  private static func makeGroup(with stack: UIStackView) -> UIView {
    let group: UIVisualEffectView
    if #available(iOS 26.0, *) {
#if os(visionOS)
      group = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
#else
      let glass = UIGlassEffect()
      glass.isInteractive = true
      group = UIVisualEffectView(effect: glass)
#endif
      group.cornerConfiguration = .capsule()
    } else {
      group = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
      group.layer.cornerRadius = itemSize / 2
      group.clipsToBounds = true
    }
    group.translatesAutoresizingMaskIntoConstraints = false
    
    stack.translatesAutoresizingMaskIntoConstraints = false
    group.contentView.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: group.contentView.topAnchor),
      stack.bottomAnchor.constraint(equalTo: group.contentView.bottomAnchor),
      stack.leadingAnchor.constraint(equalTo: group.contentView.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: group.contentView.trailingAnchor),
      group.widthAnchor.constraint(equalToConstant: itemSize),
    ])
    return group
  }
  
  /// Icon-only and monochrome, matching the close button, but on the group's
  /// capsule rather than one of its own
  private static func configure(_ button: UIButton, image: UIImage?, isDestructive: Bool = false) {
    var config = UIButton.Configuration.plain()
    config.image = image
    config.imagePlacement = .all
    config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .medium)
    config.imagePadding = 0
    config.contentInsets = .zero
    config.baseForegroundColor = isDestructive ? .systemRed : .label
    button.configuration = config
  }
  
  /// Scales icons that aren't symbols, so they match the symbols' size
  private static func icon(_ image: UIImage?) -> UIImage? {
    guard
      let image,
      !image.isSymbolImage,
      image.size.width > 0, image.size.height > 0
    else { return image }
    
    let scale = min(iconSize / image.size.width, iconSize / image.size.height)
    guard abs(scale - 1) > 0.01 else { return image }
    
    let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
    let scaled = UIGraphicsImageRenderer(size: size).image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }
    return scaled.withRenderingMode(image.renderingMode)
  }
  
}

// MARK: - Routing presentations

extension TGCardViewController {
  
  /// Presents on top of the sheet, or whatever is on top of it.
  ///
  /// The sheet is this controller's `presentedViewController`, so presenting
  /// from here directly would fail.
  func routePresentation(of viewControllerToPresent: UIViewController, above sheetHost: TGSheetHostViewController, animated: Bool, completion: (() -> Void)?) {
    // A presented view controller defines a presentation context, so presenting
    // over the current context would only cover the sheet.
    switch viewControllerToPresent.modalPresentationStyle {
    case .currentContext:     viewControllerToPresent.modalPresentationStyle = .fullScreen
    case .overCurrentContext: viewControllerToPresent.modalPresentationStyle = .overFullScreen
    default:                  break
    }
    
    var presenter: UIViewController = sheetHost
    while let next = presenter.presentedViewController, !next.isBeingDismissed {
      presenter = next
    }
    
    if presenter === sheetHost {
      sheetHost.presentDirectly(viewControllerToPresent, animated: animated, completion: completion)
    } else {
      presenter.present(viewControllerToPresent, animated: animated, completion: completion)
    }
  }
  
  /// Dismisses what's on top of the sheet, but never the sheet itself.
  func routeDismissal(above sheetHost: TGSheetHostViewController, animated: Bool, completion: (() -> Void)?) {
    if sheetHost.presentedViewController != nil {
      sheetHost.dismissPresented(animated: animated) { [weak self] in
        completion?()
        self?.updateSystemSheetPresentation()
      }
    } else if let presenting = presentingViewController {
      // Nothing's on top of the sheet, but we're presented ourselves. Like
      // UIKit, dismiss us then, which takes the sheet along.
      presenting.dismiss(animated: animated, completion: completion)
    } else {
      // Nothing to dismiss
      completion?()
    }
  }
  
}

// MARK: - Detents

extension TGCardPosition {

  var sheetDetentIdentifier: UISheetPresentationController.Detent.Identifier {
    .init("tg.\(rawValue)")
  }

  init?(sheetDetentIdentifier identifier: UISheetPresentationController.Detent.Identifier?) {
    guard let raw = identifier?.rawValue, raw.hasPrefix("tg.") else { return nil }
    self.init(rawValue: String(raw.dropFirst(3)))
  }

}

extension TGCardViewController {

  /// The positions that the sheet can rest at, smallest first.
  ///
  /// - Parameter position: The position the sheet should rest at
  private func sheetPositions(selecting position: TGCardPosition) -> [TGCardPosition] {
    let forceExtended = topCard?.mapManager == nil
    if forceExtended || !isSheetDraggingEnabled {
      // Pin the sheet where it should be
      return [position]
    } else {
      return [.collapsed, .peaking, .extended]
    }
  }

  private func makeSheetDetent(for position: TGCardPosition) -> UISheetPresentationController.Detent {
    .custom(identifier: position.sheetDetentIdentifier) { [weak self] context in
      MainActor.assumeIsolated {
        self?.sheetDetentValue(for: position, in: context) ?? context.maximumDetentValue
      }
    }
  }

  private func sheetDetentValue(for position: TGCardPosition, in context: any UISheetPresentationControllerDetentResolutionContext) -> CGFloat {
    let maximum = context.maximumDetentValue

    var extended = maximum
    if isShowingHeader {
      // Keep the header visible above the sheet
      let headerBottom = headerViewTopConstraint.constant + headerViewHeightConstraint.constant
      let available = view.bounds.height - view.safeAreaInsets.bottom - headerBottom - Constants.sheetSpacingBelowHeader
      extended = min(extended, available)
    }

    let collapsed = max(
      Constants.minCardHeightWhenCollapsed,
      topCardView?.headerHeight(for: .collapsed) ?? 0
    )

    var peaking = UISheetPresentationController.Detent.medium().resolvedValue(in: context) ?? 0
    if peaking <= 0 || peaking >= extended {
      peaking = extended / 2
    }

    // Keep them in order, and remember them all, as only the detents the sheet
    // currently uses get resolved.
    let values: [TGCardPosition: CGFloat] = [
      .collapsed: collapsed,
      .peaking: max(peaking, collapsed + 1),
      .extended: max(extended, peaking + 1, collapsed + 2),
    ]
    sheetDetentValues = values
    return values[position] ?? maximum
  }

  /// Updates the sheet's detents and selected detent.
  ///
  /// Doesn't animate by itself; call this from within `animateChanges` if needed.
  private func applySheetConfiguration(to sheet: UISheetPresentationController, selecting position: TGCardPosition) {
    let positions = sheetPositions(selecting: position)
    let identifiers = positions.map(\.sheetDetentIdentifier)

    if sheet.detents.map(\.identifier) != identifiers {
      sheet.detents = positions.map(makeSheetDetent(for:))
    } else {
      sheet.invalidateDetents()
    }

    let selected = positions.contains(position) ? position : (positions.last ?? .extended)
    if sheet.selectedDetentIdentifier != selected.sheetDetentIdentifier {
      sheet.selectedDetentIdentifier = selected.sheetDetentIdentifier
    }

    // Never dim, so that the map and the header stay interactive
    if sheet.largestUndimmedDetentIdentifier != identifiers.last {
      sheet.largestUndimmedDetentIdentifier = identifiers.last
    }

    let showGrabber = positions.count > 1
    if sheet.prefersGrabberVisible != showGrabber {
      sheet.prefersGrabberVisible = showGrabber
    }
  }

  /// Moves the sheet to the provided position, or refreshes it in place.
  ///
  /// - Parameters:
  ///   - position: Where the sheet should rest; defaults to where it's going or
  ///       resting already
  ///   - animated: Whether to animate the change
  ///   - completion: Called once the sheet has moved
  func applySheetPosition(_ position: TGCardPosition? = nil, animated: Bool, completion: (() -> Void)? = nil) {
    guard let sheet = sheetHost?.sheetPresentationController else {
      completion?()
      return
    }

    let target = position ?? sheetTargetPosition ?? cardPosition
    sheetTargetPosition = target

    guard animated else {
      applySheetConfiguration(to: sheet, selecting: target)
      completion?()
      return
    }

    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    sheet.animateChanges {
      self.applySheetConfiguration(to: sheet, selecting: target)
    }
    CATransaction.commit()
  }

  /// The sheet's position, if the cards are shown in a sheet.
  var sheetPosition: TGCardPosition? {
    guard let sheet = sheetHost?.sheetPresentationController else { return nil }
    return TGCardPosition(sheetDetentIdentifier: sheet.selectedDetentIdentifier)
      ?? TGCardPosition(sheetDetentIdentifier: sheet.detents.first?.identifier)
  }

  /// The height of the sheet when it rests at the provided position, if known.
  func sheetHeight(for position: TGCardPosition) -> CGFloat? {
    sheetDetentValues[position].map { $0 + view.safeAreaInsets.bottom }
  }

  private func estimatedSheetContentHeight(in host: TGSheetHostViewController) -> CGFloat {
    let extended = sheetHeight(for: .extended) ?? (view.bounds.height - extendedMinY)
    return max(extended, host.view.bounds.height)
  }

}

// MARK: - Following the sheet

extension TGCardViewController {

  /// Called whenever the sheet lays out, including while it's being dragged.
  func sheetHostDidLayoutSubviews() {
    guard
      let host = sheetHost,
      let window = view.window,
      host.view.window === window
    else { return }

    syncSheetHostAppearance(host)

    // Content height follows the extended detent
    if let heightConstraint = sheetContentHeightConstraint {
      let height = estimatedSheetContentHeight(in: host)
      if abs(heightConstraint.constant - height) > 0.5 {
        heightConstraint.constant = height
      }
    }

    // The invisible card wrapper mirrors the top of the sheet, which moves the
    // map buttons and the map's insets along with the sheet. Like the card
    // wrapper, its position is relative to the bottom of the header.
    let sheetTop = host.view.convert(host.view.bounds, to: view).minY
    let y = sheetTop - max(0, headerView.frame.maxY)
    if abs(cardWrapperDesiredTopConstraint.constant - y) > 0.5 {
      let insets = updateCardPosition(y: y)
      if mapViewController.additionalSafeAreaInsets != insets {
        mapViewController.additionalSafeAreaInsets = insets
      }
    }
    
    fadeMapFloatingViews(forSheetTop: sheetTop)
    
    // When the sheet settles, this is called once from within the sheet's
    // animation. Laying out now has the map buttons and insets follow along,
    // rather than jumping ahead.
    view.layoutIfNeeded()
    
    syncSheetBarItems(sheetTop: sheetTop)
  }
  
  /// Like the classic card does while dragging, fade out the map's buttons as
  /// the sheet moves up from the peaking position, so that they don't end up
  /// under the status bar.
  private func fadeMapFloatingViews(forSheetTop sheetTop: CGFloat) {
    guard
      allowFloatingViews,
      let peakingHeight = sheetHeight(for: .peaking),
      let extendedHeight = sheetHeight(for: .extended)
    else { return }
    
    let peakingTop = view.bounds.height - peakingHeight
    let extendedTop = view.bounds.height - extendedHeight
    guard peakingTop > extendedTop else { return }
    
    let fade = min(1, max(0, (peakingTop - sheetTop) / ((peakingTop - extendedTop) * 0.3)))
    topFloatingViewWrapper.alpha = 1 - fade
    bottomFloatingViewWrapper.alpha = 1 - fade
  }

  /// Called when the user dragged the sheet to a different detent.
  func sheetDidChangeSelectedDetent() {
    guard let position = sheetPosition else { return }
    sheetTargetPosition = position

    UIView.animate(withDuration: Constants.tapAnimationDuration) {
      self.updateFloatingViewsVisibility(for: position)
    }
    topCard?.mapManager?.edgePadding = mapEdgePadding(for: position)
    topCard?.didMove(to: position, animated: true)
    updateForNewPosition(position: position)
  }

}
