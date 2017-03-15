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
    
    /// The minimum number of points from the top of the card to the
    /// bottom of the screen to make sure a bit of the card is always
    /// visible.
    fileprivate static let minCardOverlap: CGFloat = 100
    
    fileprivate static let pushAnimationDuration = 0.4
    
    fileprivate static let mapShadowVisibleAlpha: CGFloat = 0.25
  }

  @IBOutlet weak var stickyBar: UIView!
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var mapShadow: UIView!
  @IBOutlet weak var cardWrapperShadow: UIView!
  @IBOutlet weak var cardWrapperContent: UIView!
  fileprivate weak var cardTransitionShadow: UIView?
  @IBOutlet weak var statusBarBlurView: UIVisualEffectView!

  // Dynamic constraints
  @IBOutlet weak var stickyBarHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var stickyBarTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var cardWrapperTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var cardWrapperHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var statusBarBlurHeightConstraint: NSLayoutConstraint!

  // Constraints to ensure cards don't get hidden
  @IBOutlet weak var fixedCardWrapperTopConstraint: NSLayoutConstraint!

  var panner: UIPanGestureRecognizer!
  
  fileprivate var isVisible = false
  
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
    let tapper = UITapGestureRecognizer()
    tapper.addTarget(self, action: #selector(handleTap))
    tapper.delegate = self
    cardWrapperContent.addGestureRecognizer(tapper)

    // Setting up additional constraints
    cardWrapperHeightConstraint.constant = extendedMinY * -1
    updateForNewTopCard()
    
    // Hide sticky bar at first
    hideStickyBar(animated: false)

    // Extend card at first
    cardWrapperTopConstraint.constant = collapsedMinY
    
    // Add a bit of a shadow behind card.
    cardWrapperShadow.layer.shadowColor = UIColor.black.cgColor
    cardWrapperShadow.layer.shadowOffset = CGSize(width: 0, height: -1)
    cardWrapperShadow.layer.shadowRadius = 3
    cardWrapperShadow.layer.shadowOpacity = 0.3
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    cards.last?.willAppear(animated: animated)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    cards.last?.didAppear(animated: animated)
    isVisible = true
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    cards.last?.willDisappear(animated: animated)
    isVisible = false
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    cards.last?.didDisappear(animated: animated)
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
  
  fileprivate enum CardPosition {
    case extended
    case peaking
    case collapsed
  }
  
  fileprivate var cardPosition: CardPosition {
    let cardY = cardWrapperTopConstraint.constant
    
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
    let overlap = topCardView?.headerHeight ?? Constants.minCardOverlap
    return view.frame.height - overlap
  }
  
  fileprivate var peakY: CGFloat {
    return (collapsedMinY - extendedMinY) / 2
  }
  
  
  /// The current amount of points of content at the top of the view
  /// that's overlapping with the map. Includes status bar, if visible.
  fileprivate var topOverlap: CGFloat {
    return UIApplication.shared.statusBarFrame.height
  }
  
  
  /// The current amount of points that the card overlaps with the map
  fileprivate var cardOverlap: CGFloat {
    guard let superview = cardWrapperContent.superview else { return 0 }
    return mapView.frame.height - superview.frame.minY
  }

  
  /// The current edge padding for the map that map managers should use
  /// to determine the zoom and scroll position of the map.
  ///
  /// - Note: This is the card's overlap for the collapsed and peaking
  ///         card positions, and capped at the peaking card position
  ///         for the extended overlap (to avoid only having a tiny
  ///         map area to work with).
  fileprivate var mapEdgePadding: UIEdgeInsets {
    let maxOverlap = mapView.frame.height - peakY
    let bottomOverlap = min(cardOverlap, maxOverlap)
    return UIEdgeInsets(top: topOverlap, left: 0, bottom: bottomOverlap, right: 0)
  }
  
  
  /// Needs to get called whenever a new top card has been added
  ///
  /// Adjusts the constraints as required, primarily the inequality
  /// constraint on the card's top spacing to make sure the card
  /// doesn't disappear when triggering the sticky bar or changing
  /// trait collections.
  fileprivate func updateForNewTopCard() {
    let overlap = topCardView?.headerHeight ?? Constants.minCardOverlap
    fixedCardWrapperTopConstraint.constant = overlap * -1
    view.setNeedsUpdateConstraints()
    view.layoutIfNeeded()
  }
  
  
  // MARK: - Card stack management
  
  fileprivate var cards = [TGCard]()
  
  func push(_ card: TGCard, animated: Bool = true) {
    var top = card

    // 1. Updating card logic and informing of transition
    let oldTop = cards.last
    let notify = isVisible
    if notify {
      oldTop?.willDisappear(animated: animated)
      top.willAppear(animated: animated)
    }
    top.controller = self
    cards.append(top)
    
    // 2. Hand over the map
    oldTop?.mapManager?.cleanUp(mapView)
    top.mapManager?.takeCharge(of: mapView, edgePadding: mapEdgePadding, animated: animated)
    
    // 3. Create and configure the new view
    let cardView = top.buildView(showClose: cards.count > 1)
    cardView.closeButton.addTarget(self, action: #selector(closeTapped(sender:)), for: .touchUpInside)
    cardView.scrollView?.isScrollEnabled = cardPosition == .extended
    
    // 4. Animate the view coming in from the bottom, with temporary shadow underneath
    cardView.frame = cardWrapperContent.bounds
    if animated {
      cardView.frame.origin.y = cardWrapperContent.frame.maxY
    }
    
    cardWrapperContent.addSubview(cardView)
    
    // 5. Special handling of when the new top card has no map content
    let forceExtended = (top.mapManager == nil)
    if forceExtended {
      cardWrapperTopConstraint.constant = extendedMinY
      view.setNeedsUpdateConstraints()
    }
    panner.isEnabled = !forceExtended
    cardView.grabHandle.isHidden = forceExtended
    
    /// Method to execute when card view is added and in its correct position,
    /// i.e., when all animations are done.
    ///
    /// - Parameter completed: If animation completed
    func whenDone(completed: Bool) {
      updateForNewTopCard()
      if notify {
        oldTop?.didDisappear(animated: animated)
        top.didAppear(animated: animated)
      }
      self.cardTransitionShadow?.removeFromSuperview()
    }
    
    if animated {
      // 6a. Do the animation
      
      if oldTop != nil {
        let shadow = TGCornerView(frame: cardWrapperContent.bounds)
        shadow.frame.size.height += 50 // for bounciness
        shadow.backgroundColor = .black
        shadow.alpha = 0
        cardWrapperContent.insertSubview(shadow, belowSubview: cardView)
        cardTransitionShadow = shadow
      }
      
      UIView.animate(
        withDuration: Constants.pushAnimationDuration,
        delay: 0,
        usingSpringWithDamping: 0.75,
        initialSpringVelocity: 0,
        options: [.curveEaseInOut],
        animations: {
          self.view.layoutIfNeeded()
          if forceExtended {
            self.mapShadow.alpha = Constants.mapShadowVisibleAlpha
          }
          cardView.frame = self.cardWrapperContent.bounds
          self.cardTransitionShadow?.alpha = 0.15
        },
        completion: whenDone)
      
    } else {
      // 6b. Finish up without animation
      view.layoutIfNeeded()
      if forceExtended {
        self.mapShadow.alpha = Constants.mapShadowVisibleAlpha
      }
      whenDone(completed: true)
    }
  }
  
  fileprivate func cardWithView(atIndex index: Int) -> (card: TGCard, view: TGCardView)? {
    let cards = self.cards
    let views = self.cardViews
    guard cards.count > index, views.count > index else { return nil }
    
    return (cards[index], views[index])
  }
  
  func pop(animated: Bool = true) {
    guard var top = cards.last, let topView = topCardView else {
      print("Nothing to pop")
      return
    }
    
    // Updating card logic and informing of transitions
    let newTop = cardWithView(atIndex: cards.count - 2)

    let notify = isVisible
    if notify {
      newTop?.card.willAppear(animated: animated)
      top.willDisappear(animated: animated)
    }
    
    top.mapManager?.cleanUp(mapView)
    newTop?.card.mapManager?.takeCharge(of: mapView, edgePadding: mapEdgePadding, animated: animated)

    // We update the stack immediately to allow calling this many times
    // while we're still animating without issues
    cards.remove(at: cards.count - 1)
    
    let forceExtended = (newTop?.card.mapManager == nil)
    if forceExtended {
      cardWrapperTopConstraint.constant = extendedMinY
      view.setNeedsUpdateConstraints()
    }
    panner.isEnabled = !forceExtended
    newTop?.view.grabHandle.isHidden = forceExtended
    
    // Clean-up when we're done. If we're not animated, that's all that's necessary
    func whenDone(completed: Bool) {
      top.controller = nil
      if notify {
        top.didDisappear(animated: animated)
        newTop?.card.didAppear(animated: animated)
      }
      topView.removeFromSuperview()
      self.cardTransitionShadow?.removeFromSuperview()
      self.updateForNewTopCard()
    }
    
    guard animated else {
      view.layoutIfNeeded()
      if forceExtended {
        self.mapShadow.alpha = Constants.mapShadowVisibleAlpha
      }
      whenDone(completed: true)
      return
    }
    
    // We animate the view moving back down to the bottom
    // we also temporarily insert a shadow view again, if there's a card below
    
    if newTop != nil {
      let shadow = TGCornerView(frame: cardWrapperContent.bounds)
      shadow.backgroundColor = .black
      shadow.alpha = 0.15
      cardWrapperContent.insertSubview(shadow, belowSubview: topView)
      cardTransitionShadow = shadow
    }
    
    UIView.animate(
      withDuration: Constants.pushAnimationDuration * 1.25,
      delay: 0,
      usingSpringWithDamping: 1,
      initialSpringVelocity: 0,
      options: [.curveEaseInOut],
      animations: {
        self.view.layoutIfNeeded()
        if forceExtended {
          self.mapShadow.alpha = Constants.mapShadowVisibleAlpha
        }
        topView.frame.origin.y = self.cardWrapperContent.frame.maxY
        self.cardTransitionShadow?.alpha = 0
      },
      completion: whenDone)
    
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
  
  fileprivate var topCardScrollView: UIScrollView? {
    return topCardView?.scrollView
  }
  
  
  /// Determines where to snap the card wrapper to, considering its current
  /// location and the provided velocity.
  ///
  /// - note:  We only go to peaking state, in regular size class.
  ///
  /// - Parameter velocity: Velocity of movement of card wrapper
  /// - Returns: Desired snap position and y
  fileprivate func determineSnap(for velocity: CGPoint) -> (position: CardPosition, y: CGFloat) {
    
    let currentCardY = cardWrapperTopConstraint.constant
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
    
    let previousCardY = cardWrapperTopConstraint.constant
    
    // Reposition the card according to the pan as long as the user
    // is dragging in the range of extended and collapsed
    if (previousCardY + translation.y >= extendedMinY) && (previousCardY + translation.y <= collapsedMinY) {
      recogniser.setTranslation(.zero, in: cardWrapperContent)
      cardWrapperTopConstraint.constant = previousCardY + translation.y
      view.setNeedsUpdateConstraints()
      view.layoutIfNeeded()
    }
    
    // Additionally, when the user is done panning, we'll snap the card
    // to the appropriate state (extended, peaking, collapsed)
    guard recogniser.state == .ended else { return }
    
    let snapTo = determineSnap(for: velocity)
    let currentCardY = cardWrapperTopConstraint.constant
    
    // Now we can animate to the new position
    var duration = direction == .up
      ? Double((currentCardY - snapTo.y) / -velocity.y)
      : Double((snapTo.y - currentCardY) / velocity.y )

    // We add a max to not make it super slow when there was
    // barely any velocity.
    // We add a min to it to make sure the alpha transition
    // animates nicely and not too suddenly.
    duration = min(max(duration, 0.25), 1.3)
    
    cardWrapperTopConstraint.constant = snapTo.y
    view.setNeedsUpdateConstraints()
    
    UIView.animate(withDuration: duration, delay: 0.0, options: [.allowUserInteraction], animations: {
      self.mapShadow.alpha = (snapTo.position == .extended) ? Constants.mapShadowVisibleAlpha : 0
      self.view.layoutIfNeeded()
      
    }, completion: { _ in
      self.topCardScrollView?.isScrollEnabled = snapTo.position == .extended
    })
  }
  
  @objc
  fileprivate func handleTap(_ recogniser: UITapGestureRecognizer) {
    
    let animateTo: (position: CardPosition, y: CGFloat)
    
    switch (cardPosition, traitCollection.verticalSizeClass) {
    case (.extended, _):          return // tapping when extended does nothing
    case (.peaking, _):           animateTo = (.extended, extendedMinY)
    case (.collapsed, .regular):  animateTo = (.peaking, peakY)
    case (.collapsed, _):         animateTo = (.extended, extendedMinY)
    }
    
    cardWrapperTopConstraint.constant = animateTo.y
    view.setNeedsUpdateConstraints()
    
    UIView.animate(
      withDuration: 0.35,
      delay: 0,
      usingSpringWithDamping: 0.75,
      initialSpringVelocity: 0,
      options: [.curveEaseOut],
      animations: {
        self.mapShadow.alpha = (animateTo.position == .extended) ? Constants.mapShadowVisibleAlpha : 0
        self.view.layoutIfNeeded()
    },
      completion: nil
    )
  }
  

  
  // MARK: - Sticky bar at the top
  
  var isShowingSticky: Bool {
    return stickyBarTopConstraint.constant > -1
  }
  
  func showStickyBar(content: UIView, animated: Bool) {
    let stickyHeight = content.frame.height
    
    overwriteStickyBarContent(with: content)
    
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

extension TGCardViewController: UIGestureRecognizerDelegate {
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    guard gestureRecognizer is UITapGestureRecognizer else { return true }
    
    // Only intercept any taps when in the collapsed states.
    // This is so that the tapper doesn't interfere with, say, taps on a table view.
    switch cardPosition {
    case .collapsed, .peaking:  return true
    case .extended:             return false
    }
  }
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    
    guard let scrollView = topCardScrollView, let panner = gestureRecognizer as? UIPanGestureRecognizer else { return false }
    
    let direction = Direction(ofVelocity: panner.velocity(in: cardWrapperContent))
    
    let y = cardWrapperTopConstraint.constant
    if (y == extendedMinY && scrollView.contentOffset.y == 0 && direction == .down) || (y == collapsedMinY) {
      scrollView.isScrollEnabled = false
    } else {
      scrollView.isScrollEnabled = true
    }
    
    return false
  }
  
}
