//
//  TGCardViewController.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//
// 
// Exception for this file. Already broken into extensions.
// swiftlint:disable file_length

import UIKit

import MapKit

public protocol TGCardViewControllerDelegate: class {
  func requestsDismissal(for controller: TGCardViewController)
}

open class TGCardViewController: UIViewController {
  
  fileprivate enum Constants {
    /// The minimum number of points between the status bar and the
    /// top of the card to keep a bit of the map always showing through.
    fileprivate static let minMapSpace: CGFloat = 50
    
    fileprivate static let pushAnimationDuration = 0.4
    
    fileprivate static let mapShadowVisibleAlpha: CGFloat = 0.25
  }
  
  open weak var delegate: TGCardViewControllerDelegate?

  @IBOutlet weak var stickyBar: UIView!
  @IBOutlet weak var headerView: UIView!
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var mapShadow: UIView!
  @IBOutlet weak var cardWrapperShadow: UIView!
  @IBOutlet public weak var cardWrapperContent: UIView!
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
  
  fileprivate var previousCardPosition: TGCardPosition?
  
  fileprivate var cards = [(card: TGCard, lastPosition: TGCardPosition)]()
  
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
  
  override open func viewDidLoad() {
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
  
  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    topCard?.willAppear(animated: animated)
  }
  
  override open func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    topCard?.didAppear(animated: animated)
    isVisible = true
  }
  
  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    topCard?.willDisappear(animated: animated)
    isVisible = false
  }
  
  override open func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    topCard?.didDisappear(animated: animated)
  }
  
  override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    
    statusBarBlurHeightConstraint.constant = topOverlap
    cardWrapperHeightConstraint.constant = extendedMinY * -1
    
    // When trait collection changes, try to keep the same card position, 
    // except in the case of compact vertical size class, which does not
    // have peak state.
    if let previous = previousCardPosition {
      // Note: Ideally, we'd determine the direction by whether the available
      // height of VC increased or decreased, but for simplicity just using
      // `up` is fine.
      cardWrapperDesiredTopConstraint.constant = cardLocation(forDesired: previous, direction: .up).y
    }
  }

  override open func didReceiveMemoryWarning() {
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
    var value = topOverlap
    
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
    return 20  // FIXME: Get status bar height properly
  }
  
  /// The edge padding for the map that map managers should use
  /// to determine the zoom and scroll position of the map.
  ///
  /// - Note: This is the card's overlap for the collapsed and peaking
  ///         card positions, and capped at the peaking card position
  ///         for the extended overlap (to avoid only having a tiny
  ///         map area to work with).
  fileprivate func mapEdgePadding(for position: TGCardPosition) -> UIEdgeInsets {
    
    let bottomOverlap: CGFloat
    let leftOverlap: CGFloat
    
    if traitCollection.horizontalSizeClass == .compact {
      // In compact width the map will always be between the card
      // and the top.
      leftOverlap = 0
      let cardY: CGFloat
      switch position {
      case .extended, .peaking: cardY = peakY
      case .collapsed:          cardY = collapsedMinY - 75 // not entirely true, but close enough
      }
      bottomOverlap = mapView.frame.height - cardY

    } else {
      // In regular width the map will be to the right of the card, which
      // we account for when not collapsed
      leftOverlap = (position != .collapsed) ? cardWrapperShadow.frame.maxX : 0
      bottomOverlap = 0
    }
    
    return UIEdgeInsets(top: topOverlap, left: leftOverlap, bottom: bottomOverlap, right: 0)
  }
  
  /// Call this whenever the card position changes to properly configure the map shadow
  ///
  /// - Parameter position: New card position
  fileprivate func updateMapShadow(for position: TGCardPosition) {
    mapShadow.alpha = position == .extended ? Constants.mapShadowVisibleAlpha : 0
    mapShadow.isUserInteractionEnabled = position == .extended
  }
  
}

// MARK: - Card stack management

extension TGCardViewController {
  
  fileprivate func cardLocation(forDesired desired: TGCardPosition?, direction: Direction)
      -> (position: TGCardPosition, y: CGFloat) {
        
    let position = desired ?? cardPosition
    
    switch (position, traitCollection.verticalSizeClass, direction) {
    case (.extended, _, _):         return (.extended, extendedMinY)
    case (.peaking, .regular, _):   return (.peaking, peakY)
    case (.peaking, _, .up):        return (.extended, extendedMinY)
    case (.peaking, _, .down):      return (.collapsed, collapsedMinY)
    case (.collapsed, _, _):        return (.collapsed, collapsedMinY)
    }
  }
  
  // Yes, these are long. We rather keep them together like this (for now).
  // swiftlint:disable function_body_length
  
  public func push(_ top: TGCard, animated: Bool = true) {
    // Set the controller on the top card earlier, because we may want
    // to ask the card to do something on willAppear, e.g., show sticky 
    // bar, which requires access to this property.
    top.controller = self
    
    // 1. Determine where the new card will go
    let forceExtended = (top.mapManager == nil)
    let animateTo = cardLocation(forDesired: forceExtended ? .extended : top.initialPosition, direction: .down)

    // 2. Updating card logic and informing of transition
    let oldTop = cardWithView(atIndex: cards.count - 1)
    let notify = isVisible
    if notify {
      oldTop?.card.willDisappear(animated: animated)
      top.willAppear(animated: animated)
    }
    
    if let oldTop = oldTop {
      cards.removeLast()
      cards.append( (oldTop.card, cardPosition) )
    }
    cards.append( (top, animateTo.position) )
    
    // 3. Hand over the map
    oldTop?.card.mapManager?.cleanUp(mapView)
    top.mapManager?.takeCharge(of: mapView, edgePadding: mapEdgePadding(for: animateTo.position), animated: animated)
    top.delegate = self
    
    // 4. Create and configure the new view
    let showClose = delegate != nil || cards.count > 1
    let cardView = top.buildCardView(showClose: showClose, includeHeader: true)
    cardView.closeButton?.addTarget(self, action: #selector(closeTapped(sender:)), for: .touchUpInside)
    
    // This allows us to continuously pull down the card view while its
    // content is scrolled to the top. Note this only applies when the
    // card isn't being forced into the extended position.
    if !forceExtended {
      cardView.contentScrollView?.panGestureRecognizer.addTarget(self, action: #selector(handleInnerPan(_:)))
    }
    
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
    cardWrapperMinOverlapTopConstraint.constant = cardView.headerHeight(for: .collapsed)
    let header = top.buildHeaderView()
    if let header = header {
      header.closeButton.addTarget(self, action: #selector(closeTapped(sender:)), for: .touchUpInside)
      showHeader(content: header, animated: animated)
    } else if isShowingHeader {
      hideHeader(animated: animated)
    }
    top.didBuild(cardView: cardView, headerView: header)
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
      completion: { _ in
        cardView.allowContentScrolling(animateTo.position == .extended)
        self.previousCardPosition = animateTo.position
        oldTop?.view.alpha = 0
        if notify {
          oldTop?.card.didDisappear(animated: animated)
          top.didAppear(animated: animated)
        }
        self.cardTransitionShadow?.removeFromSuperview()
      }
    )
  }
  
  fileprivate func cardWithView(atIndex index: Int) -> (card: TGCard, position: TGCardPosition, view: TGCardView)? {
    let cards = self.cards
    let views = self.cardViews
    guard index >= 0, index < cards.count, index < views.count else { return nil }
    
    return (cards[index].card, cards[index].lastPosition, views[index])
  }
  
  public func pop(animated: Bool = true) {
    if let delegate = delegate, cards.count == 1 {
      // popping last one, let delegate dismiss
      delegate.requestsDismissal(for: self)
      return
    }
    
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
    topView.contentScrollView?.panGestureRecognizer.removeTarget(self, action: nil)

    // We update the stack immediately to allow calling this many times
    // while we're still animating without issues
    cards.remove(at: cards.count - 1)
    
    // 2. Hand over the map
    top.mapManager?.cleanUp(mapView)
    newTop?.card.mapManager?.takeCharge(of: mapView,
                                        edgePadding: mapEdgePadding(for: newTop?.position ?? .collapsed),
                                        animated: animated)
    
    // 3. Special handling of when the new top card has no map content
    let forceExtended = (newTop?.card.mapManager == nil)
    panner.isEnabled = !forceExtended
    newTop?.view.grabHandle?.isHidden = forceExtended
    
    // 4. Determine and set new position of the card wrapper
    newTop?.view.alpha = 1
    let animateTo = cardLocation(forDesired: newTop?.position, direction: .down)
    cardWrapperDesiredTopConstraint.constant = animateTo.y
    if let new = newTop {
      cardWrapperMinOverlapTopConstraint.constant = new.view.headerHeight(for: new.position)
    } else {
      cardWrapperMinOverlapTopConstraint.constant = 0
    }
    
    // TODO: It'd be better if we didn't have to build the header again, but could
    //       just re-use it from the previous push. 
    // See https://gitlab.com/SkedGo/tripgo-cards-ios/issues/7.
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
      completion: { _ in
        newTop?.view.allowContentScrolling(animateTo.position == .extended)
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
  
  // swiftlint:enable function_body_length
  
  @objc
  func closeTapped(sender: Any) {
    pop()
  }
}


// MARK: - Dragging the card up and down

extension TGCardViewController {

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
    // swiftlint:disable fallthrough (makes sense here)
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
    // swiftlint:enable fallthrough
    
  }
  
  fileprivate func animateCardSnap(forVelocity velocity: CGPoint, completion: (() -> Void)? = nil) {
    let snapTo = determineSnap(for: velocity)
    let currentCardY = cardWrapperDesiredTopConstraint.constant
    
    // Now we can animate to the new position
    let direction = Direction(ofVelocity: velocity)
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
      self.previousCardPosition = snapTo.position
      completion?()
    })
  }
  
  @objc
  fileprivate func handlePan(_ recogniser: UIPanGestureRecognizer) {
    let translation = recogniser.translation(in: cardWrapperContent)
    let velocity = recogniser.velocity(in: cardWrapperContent)
    
    var currentCardY = cardWrapperDesiredTopConstraint.constant
    
    // Recall that we have a minimum overlap constraint set on the card 
    // view, so that a card does not collapse all the way below the view
    // but has its header remained visible. This min overlap needs to be
    // exceeded if we want to move the card upwards from the collapsed
    // state. This causes a disconnect between gesture and the movement
    // of the card, which is undesirable.
    // 
    // Care needs to be taken when accounting for the card view header.
    // When the device's size class is v(C), card only has two states:
    // collapsed and extended. Until the card has been moved past the
    // extendedY, it remains in collapsed state and we don't want to 
    // adjust the header repeatedly. Instead, we do it only when at the
    // start of recognising gesture.
    if let topCardView = topCardView, cardPosition == .collapsed, recogniser.state == .began {
      let offset = topCardView.headerHeight(for: .collapsed)
      currentCardY -= offset
    }
    
    // Reposition the card according to the pan as long as the user
    // is dragging in the range of extended and collapsed
    if (currentCardY + translation.y >= extendedMinY) && (currentCardY + translation.y <= collapsedMinY) {
      recogniser.setTranslation(.zero, in: cardWrapperContent)
      cardWrapperDesiredTopConstraint.constant = currentCardY + translation.y
      view.setNeedsUpdateConstraints()
      view.layoutIfNeeded()
    }
    
    // Additionally, when the user is done panning, we'll snap the card
    // to the appropriate state (extended, peaking, collapsed)
    guard recogniser.state == .ended else { return }
    
    animateCardSnap(forVelocity: velocity)
  }
  
  @objc
  fileprivate func handleCardTap(_ recogniser: UITapGestureRecognizer) {
    
    let desired: TGCardPosition
    switch cardPosition {
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
  
  @objc
  fileprivate func handleInnerPan(_ recogniser: UIPanGestureRecognizer) {
    guard
      let scrollView = recogniser.view as? UIScrollView,
      scrollView == topCardView?.contentScrollView
      else { return }
    
    let negativity = scrollView.contentOffset.y
    
    switch (negativity, recogniser.state) {
      
    case (0 ..< CGFloat.infinity, _):
      // Reset the transformation whenever we get back to positive offset
      scrollView.transform = .identity
      scrollView.scrollIndicatorInsets = .zero
      
    case (_, .ended), (_, .cancelled):
      // When we finish up, we bring the scroll view back to the state how
      // it's appearing: scrolled to the top with zero inset
      scrollView.transform = .identity
      scrollView.scrollIndicatorInsets = .zero
      scrollView.contentOffset = .zero
      
      let velocity = recogniser.velocity(in: cardWrapperContent)
      animateCardSnap(forVelocity: velocity)
      
    case (_, .changed):
      // This is where the magic happens: We move the card down and make
      // the scroll view appear to stay in place (it's important to not
      // set the content offset to zero here!)
      cardWrapperDesiredTopConstraint.constant = extendedMinY - negativity
      scrollView.transform = CGAffineTransform(translationX: 0, y: negativity)
      scrollView.scrollIndicatorInsets.top = negativity * -1
      
    default:
      // Ignore other states such as began, failed, etc.
      break
    }
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
        self.previousCardPosition = animateTo.position
    })
  }
  
}


// MARK: - Card-specific header view

extension TGCardViewController {

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
    headerViewTopConstraint.constant = headerView.frame.height * -1
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
  
}

// MARK: - Sticky bar at the top

extension TGCardViewController {

  public var isShowingSticky: Bool {
    return stickyBarTopConstraint.constant > -1
  }
  
  public func showStickyBar(content: UIView, animated: Bool) {
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
  
  public func hideStickyBar(animated: Bool) {
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
  
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    if cardTapper == gestureRecognizer {
      // Only intercept any taps on the title.
      // This is so that the tapper doesn't interfere with, say, taps on a table view.
      guard let view = topCardView else { return false }
      let location = touch.location(in: view)
      return location.y < view.headerHeight(for: cardPosition)
      
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
  
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer)
    -> Bool {
      
    guard
      let scrollView = topCardView?.contentScrollView,
      let panner = gestureRecognizer as? UIPanGestureRecognizer
      else {
        return false
    }
    
    let direction = Direction(ofVelocity: panner.velocity(in: cardWrapperContent))
    
    let velocity = panner.velocity(in: cardWrapperContent)
    let swipeHorizontally = fabs(velocity.x) > fabs(velocity.y)
    
    let y = cardWrapperDesiredTopConstraint.constant
    
    switch (y, scrollView.contentOffset.y, direction, swipeHorizontally) {
    case (collapsedMinY, _, _, _), (peakY, _, _, _):
      // we don't care about any other conditions, as long as the top card is at
      // one of these two positions, scrolling is disabled.
      scrollView.isScrollEnabled = false
      
    case (extendedMinY, 0, _, true):
      // while the top card is at the extended position, we are more interested
      // in finding out first if the user is panning horizontally, that is,
      // paing between pages. If they are, don't make any changes.
      break
      
    case (extendedMinY, 0, .down, _):
      // if the top card is at the extended position with its content scroll view
      // already scrolled to the top, and the user is scrolling down, scrolling is
      // disabled, so the card can be moved down to peak/collapsed position. Note,
      // this is tested after looking for horizontally swiping. If the order is
      // reversed, we could end up in a situation where a scoll view needs a 2nd
      // scroll to actually scroll up due to horizontally scrolling also carries
      // with it a vertical component.
      scrollView.isScrollEnabled = false
      
    default:
      // scrolling is enabled when the top card is at the extended position and
      // the user is scrolling up. It's also enabled when user scrolls down and
      // the scroll view isn't at its top, i.e., its content offset on the y axis
      // isn't zero.
      scrollView.isScrollEnabled = true
    }
    
    return false
  }
  
}


// MARK: - TGCardDelegate

extension TGCardViewController: TGCardDelegate {
  
  public func mapManagerDidChange(old: TGMapManager?, for card: TGCard) {
    guard card === topCard else { return }
    
    old?.cleanUp(mapView)
    card.mapManager?.takeCharge(of: mapView, edgePadding: mapEdgePadding(for: cardPosition), animated: true)
  }
  
  public func contentScrollViewDidChange(old: UIScrollView?, for card: TGCard) {
    guard card === topCard, let view = topCardView else { return }
    
    old?.panGestureRecognizer.removeTarget(self, action: nil)
    view.contentScrollView?.panGestureRecognizer.addTarget(self, action: #selector(handleInnerPan(_:)))
  }
  
}
