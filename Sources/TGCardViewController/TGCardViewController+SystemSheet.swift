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
