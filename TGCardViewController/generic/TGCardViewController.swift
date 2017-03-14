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
  }

  @IBOutlet weak var stickyBar: UIView!
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var cardWrapper: UIView!
  fileprivate weak var cardShadowView: UIView?
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
    return cardWrapper.subviews.last as? TGCardView
  }

  // MARK: - UIViewController
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Panner for dragging cards up and down
    let panGesture = UIPanGestureRecognizer()
    panGesture.addTarget(self, action: #selector(handle))
    panGesture.delegate = self
    cardWrapper.addGestureRecognizer(panGesture)

    // Setting up additional constraints
    fixedCardWrapperTopConstraint.constant = Constants.minCardOverlap * -1
    cardWrapperHeightConstraint.constant = extendedMinY * -1
    
    // Hide sticky bar at first
    hideStickyBar(animated: false)

    // Extend card at first
    cardWrapperTopConstraint.constant = extendedMinY
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
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    // Shados is added here because only at this point, we have
    // the correct frame size for the card wrapper, from which
    // the shadow was constructed.
    if !isShadowInserted {
//      addShadow()
      isShadowInserted = true
    }
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
  
  
  // MARK: - Cards
  
  fileprivate var cards = [TGCard]()
  
  fileprivate var cardOverlap: CGFloat {
    return mapView.frame.height - cardWrapper.frame.minY
  }
  
  fileprivate var mapEdgePadding: UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 0, bottom: cardOverlap, right: 0)
  }
  
  fileprivate var cardViewAnimatedEndFrame: CGRect {
    return CGRect(x: 0, y: 0, width: cardWrapper.frame.width, height: cardWrapper.frame.height)
  }
  
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
    
    // Create the new view
    let cardView = top.buildView(showClose: cards.count > 1)
    cardView.closeButton.addTarget(self, action: #selector(closeTapped(sender:)), for: .touchUpInside)
    
    // We animate the view coming in from the bottom
    // we also temporarily insert a shadow view below if there's already a card
    cardView.frame = cardViewAnimatedEndFrame
    
    if animated {
      cardView.frame.origin.y = cardWrapper.frame.maxY
    }
    
    cardWrapper.addSubview(cardView)
    
    func whenDone(completed: Bool) {
      self.cardShadowView?.removeFromSuperview()
      if notify {
        oldTop?.didDisappear(animated: animated)
        top.didAppear(animated: animated)
      }
    }
    
    if animated {
      if oldTop != nil {
        let shadow = TGCornerView(frame: cardWrapper.bounds)
        shadow.frame.size.height += 50 // for bounciness
        shadow.backgroundColor = .black
        shadow.alpha = 0
        cardWrapper.insertSubview(shadow, belowSubview: cardView)
        cardShadowView = shadow
      }
      
      UIView.animate(
        withDuration: Constants.pushAnimationDuration,
        delay: 0,
        usingSpringWithDamping: 0.75,
        initialSpringVelocity: 0,
        options: [.curveEaseInOut],
        animations: {
          cardView.frame = self.cardViewAnimatedEndFrame
          self.cardShadowView?.alpha = 0.15
        },
        completion: whenDone)
      
    } else {
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
      self.cardShadowView?.removeFromSuperview()
    }
    guard animated else { whenDone(completed: true); return }
    
    // We animate the view moving back down to the bottom
    // we also temporarily insert a shadow view again, if there's a card below
    
    if newTop != nil {
      let shadow = TGCornerView(frame: cardWrapper.bounds)
      shadow.backgroundColor = .black
      shadow.alpha = 0.15
      cardWrapper.insertSubview(shadow, belowSubview: topView)
      cardShadowView = shadow
    }
    
    UIView.animate(
      withDuration: Constants.pushAnimationDuration * 1.25,
      delay: 0,
      usingSpringWithDamping: 1,
      initialSpringVelocity: 0,
      options: [.curveEaseInOut],
      animations: {
        topView.frame.origin.y = self.cardWrapper.frame.maxY
        self.cardShadowView?.alpha = 0
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
  
  fileprivate var extendedMinY: CGFloat {
    var value: CGFloat = UIApplication.shared.statusBarFrame.height
    
    if let navigationBar = navigationController?.navigationBar {
      value += navigationBar.frame.height
    }
    
    value += Constants.minMapSpace
    
    return value
  }
  
  fileprivate var collapsedMinY: CGFloat {
    return view.frame.height - Constants.minCardOverlap
  }
  
  fileprivate var topCardScrollView: UIScrollView? {
    return topCardView?.scrollView
  }
  
  @objc
  fileprivate func handle(_ recogniser: UIPanGestureRecognizer) {
    let translation = recogniser.translation(in: cardWrapper)
    let velocity = recogniser.velocity(in: cardWrapper)
    let direction = Direction(ofVelocity: velocity)
    
    let y = cardWrapperTopConstraint.constant
    if (y + translation.y >= extendedMinY) && (y + translation.y <= collapsedMinY) {
      recogniser.setTranslation(.zero, in: cardWrapper)
      cardWrapperTopConstraint.constant = y + translation.y
      view.setNeedsUpdateConstraints()
      view.layoutIfNeeded()
    }
    
    // Additionally, when we're done and there's a velocity, we'll
    // animate snapping to the bottom or top
    guard recogniser.state == .ended else { return }
    
    var duration = direction == .up
      ? Double((y - extendedMinY) / -velocity.y)
      : Double((collapsedMinY - y) / velocity.y )
    
    duration = duration > 1.3 ? 1 : duration
    
    cardWrapperTopConstraint.constant = direction == .up ? extendedMinY : collapsedMinY
    view.setNeedsUpdateConstraints()
    
    UIView.animate(withDuration: duration, delay: 0.0, options: [.allowUserInteraction], animations: {
      self.view.layoutIfNeeded()
      
    }, completion: { _ in
      if direction == .up {
        self.topCardScrollView?.isScrollEnabled = true
      }
    })
  }

  
  // MARK: - Sticky bar at the top
  
  var isShowingSticky: Bool {
    return self.stickyBarTopConstraint.constant > -1
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
  
  // MARK: - Styling
  
  fileprivate var isShadowInserted = false
  
  fileprivate func addShadow() {
    let shadowFrame = cardWrapper.frame
    let shadow = UIView(frame: shadowFrame)
    shadow.isUserInteractionEnabled = true
    shadow.layer.shadowColor = UIColor.black.cgColor
    shadow.layer.shadowOffset = CGSize(width: 0, height: -1)
    shadow.layer.shadowRadius = 5
    shadow.layer.shadowOpacity = 0.3
    shadow.layer.masksToBounds = false
    shadow.clipsToBounds = false
    cardWrapper.superview?.insertSubview(shadow, belowSubview: cardWrapper)
    shadow.addSubview(cardWrapper)
  }

}

extension TGCardViewController: UIGestureRecognizerDelegate {
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    
    guard let scrollView = topCardScrollView, let panner = gestureRecognizer as? UIPanGestureRecognizer else { return false }
    
    let direction = Direction(ofVelocity: panner.velocity(in: cardWrapper))
    
    let y = cardWrapperTopConstraint.constant
    if (y == extendedMinY && scrollView.contentOffset.y == 0 && direction == .down) || (y == collapsedMinY) {
      scrollView.isScrollEnabled = false
    } else {
      scrollView.isScrollEnabled = true
    }
    
    return false
  }
  
}
