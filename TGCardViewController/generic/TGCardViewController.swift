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
  
  fileprivate var isVisible = false
  
  fileprivate var topCardView: TGCardView? {
    return cardWrapperContent.subviews.last as? TGCardView
  }

  // MARK: - UIViewController
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Panner for dragging cards up and down
    let panGesture = UIPanGestureRecognizer()
    panGesture.addTarget(self, action: #selector(handlePan))
    panGesture.delegate = self
    cardWrapperContent.addGestureRecognizer(panGesture)
    
    // Tapper for tapping the title of the cards
    let tapper = UITapGestureRecognizer()
    tapper.addTarget(self, action: #selector(handleTap))
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

    // Updating card logic and informing of transition
    let oldTop = cards.last
    let notify = isVisible
    if notify {
      oldTop?.willDisappear(animated: animated)
      top.willAppear(animated: animated)
    }
    top.controller = self
    cards.append(top)
    
    oldTop?.mapManager?.cleanUp(mapView)
    top.mapManager?.takeCharge(of: mapView, edgePadding: mapEdgePadding, animated: animated)
    
    // Create and configure the new view
    let cardView = top.buildView(showClose: cards.count > 1)
    cardView.closeButton.addTarget(self, action: #selector(closeTapped(sender:)), for: .touchUpInside)
    cardView.scrollView?.isScrollEnabled = cardPosition == .extended
    
    // We animate the view coming in from the bottom
    // we also temporarily insert a shadow view below if there's already a card
    
    func cardViewAnimatedEndFrame() -> CGRect {
      return CGRect(x: 0, y: 0, width: cardWrapperContent.frame.width, height: cardWrapperContent.frame.height)
    }
    cardView.frame = cardViewAnimatedEndFrame()
    if animated {
      cardView.frame.origin.y = cardWrapperContent.frame.maxY
    }
    
    cardWrapperContent.addSubview(cardView)
    
    let forceExtended = (top.mapManager == nil)
    if forceExtended {
      cardWrapperTopConstraint.constant = extendedMinY
      view.setNeedsUpdateConstraints()
    }
    
    func whenDone(completed: Bool) {
      updateForNewTopCard()
      if notify {
        oldTop?.didDisappear(animated: animated)
        top.didAppear(animated: animated)
      }
      self.cardTransitionShadow?.removeFromSuperview()
    }
    
    if animated {
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
          cardView.frame = cardViewAnimatedEndFrame()
          self.cardTransitionShadow?.alpha = 0.15
        },
        completion: whenDone)
      
    } else {
      view.layoutIfNeeded()
      if forceExtended {
        self.mapShadow.alpha = 0.15
      }
      whenDone(completed: true)
    }
  }
  
  func pop(animated: Bool = true) {
    guard var top = cards.last, let topView = topCardView else {
      print("Nothing to pop")
      return
    }
    
    // Updating card logic and informing of transitions
    let newTop: TGCard? = cards.count > 1 ? cards[cards.count - 2] : nil
    let notify = isVisible
    if notify {
      newTop?.willAppear(animated: animated)
      top.willDisappear(animated: animated)
    }
    
    top.mapManager?.cleanUp(mapView)
    newTop?.mapManager?.takeCharge(of: mapView, edgePadding: mapEdgePadding, animated: animated)

    // We update the stack immediately to allow calling this many times
    // while we're still animating without issues
    cards.remove(at: cards.count - 1)
    
    // Clean-up when we're done. If we're not animated, that's all that's necessary
    func whenDone(completed: Bool) {
      top.controller = nil
      if notify {
        top.didDisappear(animated: animated)
        newTop?.didAppear(animated: animated)
      }
      topView.removeFromSuperview()
      self.cardTransitionShadow?.removeFromSuperview()
      self.updateForNewTopCard()
    }
    guard animated else { whenDone(completed: true); return }
    
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
    
    let currentCardY = cardWrapperTopConstraint.constant
    let nextCardY = currentCardY + velocity.y / 5 // in a fraction of a second
    
    // Where we snap to depends on where the card currently is,
    // the direction and speed at the end of the pan. Also,
    // we only go to peaking state, in regular size class.
    let snapTo: (position: CardPosition, y: CGFloat)
    switch (direction, traitCollection.verticalSizeClass) {
    case (.up, .compact): fallthrough
    case (.up, _) where nextCardY < peakY:
      snapTo = (.extended, extendedMinY)

    case (.down, .compact): fallthrough
    case (.down, _) where nextCardY > peakY:
      snapTo = (.collapsed, collapsedMinY)

    default:
      snapTo = (.peaking, peakY)
    }
    
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
