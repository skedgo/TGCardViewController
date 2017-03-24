//
//  TGCardViewController.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import MapKit

class TGCardViewController: UIViewController {
  
  fileprivate enum Constants {
    /// The minimum number of points between the status bar and the
    /// top of the card to keep a bit of the map always showing through.
    fileprivate static let minMapSpace: CGFloat = 50
    
    fileprivate static let pushAnimationDuration = 0.4
    
    fileprivate static let mapShadowVisibleAlpha: CGFloat = 0.25
  }

  @IBOutlet weak var stickyBar: UIView!
  @IBOutlet weak var headerView: UIView!
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var mapShadow: UIView!
  @IBOutlet weak var cardWrapperShadow: UIView!
  @IBOutlet weak var cardWrapperContent: UIView!
  fileprivate weak var cardTransitionShadow: UIView?
  @IBOutlet weak var statusBarBlurView: UIVisualEffectView!

  // Positioning the cards
  @IBOutlet weak var cardWrapperDesiredTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var cardWrapperMinOverlapTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var cardWrapperHeightConstraint: NSLayoutConstraint!
  
  // Positioning the header view
  @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var headerViewTopConstraint: NSLayoutConstraint!
  
  // Positioning the sticky bar
  @IBOutlet weak var stickyBarHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var stickyBarTopConstraint: NSLayoutConstraint!
  
  // Dynamic constraints
  @IBOutlet weak var statusBarBlurHeightConstraint: NSLayoutConstraint!

  var panner: UIPanGestureRecognizer!
  var cardTapper: UITapGestureRecognizer!
  var mapShadowTapper: UITapGestureRecognizer!
  
  fileprivate var isVisible = false
  
  fileprivate var topCard: TGCard? {
    return cards.last?.card
  }
  
  fileprivate var cardViews: [TGCardView] {
    return cardWrapperContent.subviews.flatMap { $0 as? TGCardView }
  }
  
  fileprivate var topCardView: TGCardView? {
    return cardViews.last
  }

  // MARK: - UIViewController
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Panner for dragging cards up and down
    let panGesture = UIPanGestureRecognizer()
    panGesture.addTarget(self, action: #selector(handlePan))
    panGesture.delegate = self
    cardWrapperContent.addGestureRecognizer(panGesture)
    panner = panGesture
    
    // Tapper for tapping the title of the cards
    let cardTapper = UITapGestureRecognizer()
    cardTapper.addTarget(self, action: #selector(handleCardTap))
    cardTapper.delegate = self
    cardWrapperContent.addGestureRecognizer(cardTapper)
    self.cardTapper = cardTapper

    // Tapper for tapping the map shadow
    let mapTapper = UITapGestureRecognizer()
    mapTapper.addTarget(self, action: #selector(handleMapTap))
    mapTapper.delegate = self
    mapShadow.addGestureRecognizer(mapTapper)
    self.mapShadowTapper = mapTapper
    
    // Setting up additional constraints
    cardWrapperHeightConstraint.constant = extendedMinY * -1
    cardWrapperMinOverlapTopConstraint.constant = 0
    
    // Hide the bars at first
    hideStickyBar(animated: false)
    hideHeader(animated: false)

    // Collapse card at first
    cardWrapperDesiredTopConstraint.constant = collapsedMinY
    
    // Add a bit of a shadow behind card.
    cardWrapperShadow.layer.shadowColor = UIColor.black.cgColor
    cardWrapperShadow.layer.shadowOffset = CGSize(width: 0, height: -1)
    cardWrapperShadow.layer.shadowRadius = 3
    cardWrapperShadow.layer.shadowOpacity = 0.3
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    topCard?.willAppear(animated: animated)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    topCard?.didAppear(animated: animated)
    isVisible = true
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    topCard?.willDisappear(animated: animated)
    isVisible = false
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    topCard?.didDisappear(animated: animated)
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    
    statusBarBlurHeightConstraint.constant = UIApplication.shared.statusBarFrame.height
    cardWrapperHeightConstraint.constant = extendedMinY * -1
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  // MARK: - Card positioning
  
  fileprivate var cardPosition: TGCardPosition {
    let cardY = cardWrapperDesiredTopConstraint.constant
    
    switch (cardY, traitCollection.verticalSizeClass) {
    case (0..<peakY, _):                      return .extended
    case (peakY..<collapsedMinY, .regular):   return .peaking
    default:                                  return .collapsed
    }
  }
  
  fileprivate var extendedMinY: CGFloat {
    var value: CGFloat = UIApplication.shared.statusBarFrame.height
    
    if let navigationBar = navigationController?.navigationBar {
      value += navigationBar.frame.height
    }
    
    value += Constants.minMapSpace
    
    return value
  }
  
  fileprivate var collapsedMinY: CGFloat {
    // It is save to use the full height of the frame, when actually
    // positioning the card, the fixedCardWrapperTopConstraint will
    // make sure that the top of the card remains visible.
    return view.frame.height
  }
  
  fileprivate var peakY: CGFloat {
    return (collapsedMinY - extendedMinY) / 2
  }
  
  
  /// The current amount of points of content at the top of the view
  /// that's overlapping with the map. Includes status bar, if visible.
  fileprivate var topOverlap: CGFloat {
    return UIApplication.shared.statusBarFrame.height
  }
  
  
  /// The edge padding for the map that map managers should use
  /// to determine the zoom and scroll position of the map.
  ///
  /// - Note: This is the card's overlap for the collapsed and peaking
  ///         card positions, and capped at the peaking card position
  ///         for the extended overlap (to avoid only having a tiny
  ///         map area to work with).
  fileprivate func mapEdgePadding(for position: TGCardPosition) -> UIEdgeInsets {
    let cardY: CGFloat
    switch position {
    case .extended, .peaking: cardY = peakY
    case .collapsed:          cardY = collapsedMinY - 75 // not entirely true, but close enough
    }
    let bottomOverlap = mapView.frame.height - cardY
    return UIEdgeInsets(top: topOverlap, left: 0, bottom: bottomOverlap, right: 0)
  }
  
  
  /// Call this whenever the card position changes to properly configure the map shadow
  ///
  /// - Parameter position: New card position
  fileprivate func updateMapShadow(for position: TGCardPosition) {
    mapShadow.alpha = position == .extended ? Constants.mapShadowVisibleAlpha : 0
    mapShadow.isUserInteractionEnabled = position == .extended
  }
  
  
  // MARK: - Card stack management
  
  fileprivate var cards = [(card: TGCard, lastPosition: TGCardPosition)]()
  
  
  fileprivate func cardLocation(forDesired position: TGCardPosition?, direction: Direction) -> (position: TGCardPosition, y: CGFloat) {
    guard let position = position else { return (.collapsed, collapsedMinY) }
    
    switch (position, traitCollection.verticalSizeClass, direction) {
    case (.extended, _, _):         return (.extended, extendedMinY)
    case (.peaking, .regular, _):   return (.peaking, peakY)
    case (.peaking, _, .up):        return (.extended, extendedMinY)
    case (.peaking, _, .down):      return (.collapsed, collapsedMinY)
    case (.collapsed, _, _):        return (.collapsed, collapsedMinY)
    }
  }
  
  
  func push(_ top: TGCard, animated: Bool = true) {
    
    // Set the controller on the top card earlier, because we may want
    // to ask the card to do something on willAppear, e.g., show sticky 
    // bar, which requires access to this property.
    top.controller = self
    
    // 1. Determine where the new card will go
    let forceExtended = (top.mapManager == nil)
    let animateTo = cardLocation(forDesired: forceExtended ? .extended : top.defaultPosition, direction: .down)

    // 2. Updating card logic and informing of transition
    let oldTop = topCard
    let notify = isVisible
    if notify {
      oldTop?.willDisappear(animated: animated)
      top.willAppear(animated: animated)
    }
    
    if let oldTop = oldTop {
      cards.removeLast()
      cards.append( (oldTop, cardPosition) )
    }
    cards.append( (top, animateTo.position) )
    
    // 3. Hand over the map
    oldTop?.mapManager?.cleanUp(mapView)
    top.mapManager?.takeCharge(of: mapView, edgePadding: mapEdgePadding(for: animateTo.position), animated: animated)
    top.delegate = self
    
    // 4. Create and configure the new view
    let cardView = top.buildCardView(showClose: cards.count > 1, includeHeader: true)
    cardView.closeButton?.addTarget(self, action: #selector(closeTapped(sender:)), for: .touchUpInside)
    
    // 5. Place the new view coming, preparing to animate in from the bottom
    cardView.frame = cardWrapperContent.bounds
    if animated {
      cardView.frame.origin.y = cardWrapperContent.frame.maxY
    }
    cardWrapperContent.addSubview(cardView)
    
    // Give AutoLayout a nudge to layout the card view, now that we have
    // the right hight. This is so that we can use `cardView.headerHeight`.
    cardView.setNeedsUpdateConstraints()
    cardView.layoutIfNeeded()
    
    // 6. Special handling of when the new top card has no map content
    panner.isEnabled = !forceExtended
    cardView.grabHandle?.isHidden = forceExtended
    
    // 7. Set new position of the wrapper
    cardWrapperDesiredTopConstraint.constant = animateTo.y
    cardWrapperMinOverlapTopConstraint.constant = cardView.headerHeight
    if let header = top.buildHeaderView() {
      header.closeButton.addTarget(self, action: #selector(closeTapped(sender:)), for: .touchUpInside)
      showHeader(content: header, animated: animated)
    } else if isShowingHeader {
      hideHeader(animated: animated)
    }
    view.setNeedsUpdateConstraints()
    
    // 8. Do the transition, optionally animated
    // We insert a temporary shadow underneath the new top view and above the old
    
    if oldTop != nil && animated {
      let shadow = TGCornerView(frame: cardWrapperContent.bounds)
      shadow.frame.size.height += 50 // for bounciness
      shadow.backgroundColor = .black
      shadow.alpha = 0
      cardWrapperContent.insertSubview(shadow, belowSubview: cardView)
      cardTransitionShadow = shadow
    }
    
    UIView.animate(
      withDuration: animated ? Constants.pushAnimationDuration : 0,
      delay: 0,
      usingSpringWithDamping: 0.75,
      initialSpringVelocity: 0,
      options: [.curveEaseInOut],
      animations: {
        self.view.layoutIfNeeded()
        self.updateMapShadow(for: animateTo.position)
        cardView.frame = self.cardWrapperContent.bounds
        self.cardTransitionShadow?.alpha = 0.15
      },
      completion: { finished in
        self.topCardView?.allowContentScrolling(animateTo.position == .extended)
        if notify {
          oldTop?.didDisappear(animated: animated)
          top.didAppear(animated: animated)
        }
        self.cardTransitionShadow?.removeFromSuperview()
      }
    )
  }
  
  fileprivate func cardWithView(atIndex index: Int) -> (card: TGCard, position: TGCardPosition, view: TGCardView)? {
    let cards = self.cards
    let views = self.cardViews
    guard cards.count > index, views.count > index else { return nil }
    
    return (cards[index].card, cards[index].lastPosition, views[index])
  }
  
  func pop(animated: Bool = true) {
    guard let top = topCard, let topView = topCardView else {
      print("Nothing to pop")
      return
    }

    let newTop = cardWithView(atIndex: cards.count - 2)
    
    // 1. Updating card logic and informing of transitions
    let notify = isVisible
    if notify {
      newTop?.card.willAppear(animated: animated)
      top.willDisappear(animated: animated)
    }

    // We update the stack immediately to allow calling this many times
    // while we're still animating without issues
    cards.remove(at: cards.count - 1)
    
    // 2. Hand over the map
    top.mapManager?.cleanUp(mapView)
    newTop?.card.mapManager?.takeCharge(of: mapView, edgePadding: mapEdgePadding(for: newTop?.position ?? .collapsed), animated: animated)
    
    // 3. Special handling of when the new top card has no map content
    let forceExtended = (newTop?.card.mapManager == nil)
    panner.isEnabled = !forceExtended
    newTop?.view.grabHandle?.isHidden = forceExtended
    
    // 4. Determine and set new position of the card wrapper
    let animateTo = cardLocation(forDesired: newTop?.position, direction: .down)
    cardWrapperDesiredTopConstraint.constant = animateTo.y
    cardWrapperMinOverlapTopConstraint.constant = newTop?.view.headerHeight ?? 0
    if let header = newTop?.card.buildHeaderView() {
      showHeader(content: header, animated: animated)
    } else if isShowingHeader {
      hideHeader(animated: animated)
    }
    view.setNeedsUpdateConstraints()

    // 5. Do the transition, optionally animated.
    // We animate the view moving back down to the bottom
    // we also temporarily insert a shadow view again, if there's a card below
    
    if animated && newTop != nil {
      let shadow = TGCornerView(frame: cardWrapperContent.bounds)
      shadow.backgroundColor = .black
      shadow.alpha = 0.15
      cardWrapperContent.insertSubview(shadow, belowSubview: topView)
      cardTransitionShadow = shadow
    }
    
    UIView.animate(
      withDuration: animated ? Constants.pushAnimationDuration * 1.25 : 0,
      delay: 0,
      usingSpringWithDamping: 1,
      initialSpringVelocity: 0,
      options: [.curveEaseInOut],
      animations: {
        self.view.layoutIfNeeded()
        self.updateMapShadow(for: animateTo.position)
        topView.frame.origin.y = self.cardWrapperContent.frame.maxY
        self.cardTransitionShadow?.alpha = 0
      },
      completion: { completed in
        self.topCardView?.allowContentScrolling(animateTo.position == .extended)
        top.controller = nil
        if notify {
          top.didDisappear(animated: animated)
          newTop?.card.didAppear(animated: animated)
        }
        topView.removeFromSuperview()
        self.cardTransitionShadow?.removeFromSuperview()
      }
    )
    
  }
  
  @objc
  func closeTapped(sender: Any) {
    pop()
  }
  
  // MARK: - Dragging the card up and down

  fileprivate enum Direction {
    case up
    case down
    
    init(ofVelocity velocity: CGPoint) {
      if velocity.y < 0 {
        self = .up
      } else {
        self = .down
      }
    }
  }
  
  /// Determines where to snap the card wrapper to, considering its current
  /// location and the provided velocity.
  ///
  /// - note:  We only go to peaking state, in regular size class.
  ///
  /// - Parameter velocity: Velocity of movement of card wrapper
  /// - Returns: Desired snap position and y
  fileprivate func determineSnap(for velocity: CGPoint) -> (position: TGCardPosition, y: CGFloat) {
    
    let currentCardY = cardWrapperDesiredTopConstraint.constant
    let nextCardY = currentCardY + velocity.y / 5 // in a fraction of a second
    
    // First we see if the card is close to a target snap position, then we use that
    let delta: CGFloat = 22
    switch (nextCardY, traitCollection.verticalSizeClass) {
    case (extendedMinY - delta ..< extendedMinY + delta, _):
      return (.extended, extendedMinY)
    case (peakY - delta * 2 ..< peakY + delta * 2, .regular):
      return (.peaking, peakY)
    case (collapsedMinY - delta ..< collapsedMinY + delta, _):
      return (.collapsed, collapsedMinY)
    
    default:
      break // not near a target position
    }
    
    // Otherwise we look into the direction and snap to the next one that way
    let direction = Direction(ofVelocity: velocity)
    switch (direction, traitCollection.verticalSizeClass) {
    case (.up, .compact): fallthrough
    case (.up, _) where nextCardY < peakY:
      return (.extended, extendedMinY)
      
    case (.down, .compact): fallthrough
    case (.down, _) where nextCardY > peakY:
      return (.collapsed, collapsedMinY)
      
    default:
      return (.peaking, peakY)
    }
    
  }
  
  @objc
  fileprivate func handlePan(_ recogniser: UIPanGestureRecognizer) {
    let translation = recogniser.translation(in: cardWrapperContent)
    let velocity = recogniser.velocity(in: cardWrapperContent)
    let direction = Direction(ofVelocity: velocity)
    
    let previousCardY = cardWrapperDesiredTopConstraint.constant
    
    // Reposition the card according to the pan as long as the user
    // is dragging in the range of extended and collapsed
    if (previousCardY + translation.y >= extendedMinY) && (previousCardY + translation.y <= collapsedMinY) {
      recogniser.setTranslation(.zero, in: cardWrapperContent)
      cardWrapperDesiredTopConstraint.constant = previousCardY + translation.y
      view.setNeedsUpdateConstraints()
      view.layoutIfNeeded()
    }
    
    // Additionally, when the user is done panning, we'll snap the card
    // to the appropriate state (extended, peaking, collapsed)
    guard recogniser.state == .ended else { return }
    
    let snapTo = determineSnap(for: velocity)
    let currentCardY = cardWrapperDesiredTopConstraint.constant
    
    // Now we can animate to the new position
    var duration = direction == .up
      ? Double((currentCardY - snapTo.y) / -velocity.y)
      : Double((snapTo.y - currentCardY) / velocity.y )

    // We add a max to not make it super slow when there was
    // barely any velocity.
    // We add a min to it to make sure the alpha transition
    // animates nicely and not too suddenly.
    duration = min(max(duration, 0.25), 1.3)
    
    cardWrapperDesiredTopConstraint.constant = snapTo.y
    view.setNeedsUpdateConstraints()
    
    UIView.animate(withDuration: duration, delay: 0.0, options: [.allowUserInteraction], animations: {
      self.updateMapShadow(for: snapTo.position)
      self.view.layoutIfNeeded()
      
    }, completion: { _ in
      self.topCardView?.allowContentScrolling(snapTo.position == .extended)
    })
  }
  
  @objc
  fileprivate func handleCardTap(_ recogniser: UITapGestureRecognizer) {
    
    let desired: TGCardPosition
    switch (cardPosition) {
    case (.extended):  return // tapping when extended does nothing
    case (.peaking):   desired = .extended
    case (.collapsed): desired = .peaking
    }
    
    switchTo(desired, direction: .up, animated: true)
  }
  
  @objc
  fileprivate func handleMapTap(_ recogniser: UITapGestureRecognizer) {
    guard cardPosition == .extended, topCard?.mapManager != nil else { return }
    
    switchTo(.peaking, direction: .down, animated: true)
  }
  
  fileprivate func switchTo(_ position: TGCardPosition, direction: Direction, animated: Bool) {
    let animateTo = cardLocation(forDesired: position, direction: direction)
    
    cardWrapperDesiredTopConstraint.constant = animateTo.y
    view.setNeedsUpdateConstraints()
    
    UIView.animate(
      withDuration: animated ? 0.35 : 0,
      delay: 0,
      usingSpringWithDamping: 0.75,
      initialSpringVelocity: 0,
      options: [.curveEaseOut],
      animations: {
        self.updateMapShadow(for: animateTo.position)
        self.view.layoutIfNeeded()
    },
      completion: { _ in
        self.topCardView?.allowContentScrolling(animateTo.position == .extended)
    })
  }
  
  
  // MARK: - Card-specific header view
  
  fileprivate var isShowingHeader: Bool {
    return headerViewTopConstraint.constant > -1
  }
  
  fileprivate func showHeader(content: UIView, animated: Bool) {
    // It's okay to do replacement here, even though the height of the
    // sticky bar may not fit the content. This is because the height
    // constraint on the sticky bar has lower priority, so AL can break
    // it if conflicts arise.
    overwriteHeaderContent(with: content)
    
    // The content view passed in here may be loaded from xib, to get
    // the correct height, we need to adjust its width and ask the AL
    // to compute the fitting height.
    content.frame.size.width = headerView.frame.width
    
    // Do a layout pass, just to make sure its subviews are still laid
    // out correctly after the change in width.
    content.setNeedsLayout()
    content.layoutIfNeeded()
    
    // Ask the AL for the most fitting height.
    let headerHeight = content.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
    
    headerViewHeightConstraint.constant = headerHeight
    headerViewTopConstraint.constant = 0
    view.setNeedsUpdateConstraints()

    UIView.animate(
      withDuration: animated ? 0.35 : 0,
      delay: 0,
      usingSpringWithDamping: 0.75,
      initialSpringVelocity: 0,
      options: [.curveEaseOut],
      animations: {
        self.view.layoutIfNeeded()
      },
      completion: nil
    )
  }
  
  fileprivate func hideHeader(animated: Bool) {
    let headerHeight = headerViewHeightConstraint.constant
    
    headerViewTopConstraint.constant = headerHeight * -1
    view.setNeedsUpdateConstraints()

    UIView.animate(
      withDuration: animated ? 0.35 : 0,
      delay: 0,
      usingSpringWithDamping: 0.75,
      initialSpringVelocity: 0,
      options: [.curveEaseIn],
      animations: {
        self.view.layoutIfNeeded()
      },
      completion: { finished in
        guard finished else { return }
        self.headerView.subviews.forEach { $0.removeFromSuperview() }
      }
    )
  }
  
  fileprivate func overwriteHeaderContent(with content: UIView) {
    headerView.subviews.forEach { $0.removeFromSuperview() }
    content.translatesAutoresizingMaskIntoConstraints = false
    headerView.addSubview(content)
    content.leadingAnchor.constraint(equalTo: headerView.leadingAnchor).isActive = true
    content.trailingAnchor.constraint(equalTo: headerView.trailingAnchor).isActive = true
    content.topAnchor.constraint(equalTo: headerView.topAnchor).isActive = true
    content.bottomAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
  }
  
  
  // MARK: - Sticky bar at the top
  
  var isShowingSticky: Bool {
    return stickyBarTopConstraint.constant > -1
  }
  
  func showStickyBar(content: UIView, animated: Bool) {
    // It's okay to do replacement here, even though the height of the
    // sticky bar may not fit the content. This is because the height
    // constraint on the sticky bar has lower priority, so AL can break
    // it if conflicts arise.
    overwriteStickyBarContent(with: content)
    
    // The content view passed in here may be loaded from xib, to get
    // the correct height, we need to adjust its width and ask the AL
    // to compute the fitting height.
    content.frame.size.width = stickyBar.frame.width
    
    // Do a layout pass, just to make sure its subviews are still laid
    // out correctly after the change in width.
    content.setNeedsLayout()
    content.layoutIfNeeded()
    
    // Ask the AL for the most fitting height.
    let stickyHeight = content.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
    
    stickyBarHeightConstraint.constant = stickyHeight
    stickyBarTopConstraint.constant = 0
    view.setNeedsUpdateConstraints()

    UIView.animate(
      withDuration: animated ? 0.35 : 0,
      delay: 0,
      usingSpringWithDamping: 0.75,
      initialSpringVelocity: 0,
      options: [.curveEaseOut],
      animations: {
        self.view.layoutIfNeeded()
      },
      completion: nil
    )
  }
  
  func hideStickyBar(animated: Bool) {
    let stickyHeight = stickyBarHeightConstraint.constant
    
    stickyBarTopConstraint.constant = stickyHeight * -1
    view.setNeedsUpdateConstraints()

    UIView.animate(
      withDuration: animated ? 0.35 : 0,
      delay: 0,
      usingSpringWithDamping: 0.75,
      initialSpringVelocity: 0,
      options: [.curveEaseIn],
      animations: {
        self.view.layoutIfNeeded()
      },
      completion: { finished in
        guard finished else { return }
        self.stickyBar.subviews.forEach { $0.removeFromSuperview() }
      }
    )
  }
  
  fileprivate func overwriteStickyBarContent(with content: UIView) {
    stickyBar.subviews.forEach { $0.removeFromSuperview() }
    content.translatesAutoresizingMaskIntoConstraints = false
    stickyBar.addSubview(content)
    content.leadingAnchor.constraint(equalTo: stickyBar.leadingAnchor).isActive = true
    content.trailingAnchor.constraint(equalTo: stickyBar.trailingAnchor).isActive = true
    content.topAnchor.constraint(equalTo: stickyBar.topAnchor).isActive = true
    content.bottomAnchor.constraint(equalTo: stickyBar.bottomAnchor).isActive = true
  }
  
  
}


// MARK: - UIGestureRecognizerDelegate

extension TGCardViewController: UIGestureRecognizerDelegate {
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    
    if cardTapper == gestureRecognizer {
      // Only intercept any taps on the title.
      // This is so that the tapper doesn't interfere with, say, taps on a table view.
      guard let view = topCardView else { return false }
      let location = touch.location(in: view)
      return location.y < view.headerHeight
      
    } else if mapShadowTapper == gestureRecognizer {
      // Only intercept any taps when in the expanded state.
      // This is so that the tapper doesn't interfere with taps on the map
      switch cardPosition {
      case .extended:             return true
      case .collapsed, .peaking:  return false
      }
      
    } else {
      return true
    }
    
  }
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    
    guard let scrollView = topCardView?.contentScrollView, let panner = gestureRecognizer as? UIPanGestureRecognizer else { return false }
    
//    print("(before - panner: \(panner.isEnabled), scrolling: \(scrollView.isScrollEnabled), paging: \(scrollView.isPagingEnabled))")
    
    let direction = Direction(ofVelocity: panner.velocity(in: cardWrapperContent))
    
    let velocity = panner.velocity(in: cardWrapperContent)
    let isPanningHorizontally = fabs(velocity.x) > fabs(velocity.y)
    
    let y = cardWrapperDesiredTopConstraint.constant
    if (y == extendedMinY && scrollView.contentOffset.y == 0 && direction == .down) || (y == collapsedMinY) {
      scrollView.isScrollEnabled = false || isPanningHorizontally
    } else {
      scrollView.isScrollEnabled = true
    }
    
    print("(after - panner: \(panner.isEnabled), scrolling: \(scrollView.isScrollEnabled), paging: \(scrollView.isPagingEnabled), scroller: \(scrollView))")
    
    return false
  }
  
}


// MARK: - TGCardDelegate

extension TGCardViewController: TGCardDelegate {
  
  func mapManagerDidChange(old: TGMapManager?, for card: TGCard) {
    guard card === topCard else { return }
    
    old?.cleanUp(mapView)
    card.mapManager?.takeCharge(of: mapView, edgePadding: mapEdgePadding(for: cardPosition), animated: true)
  }
  
}
