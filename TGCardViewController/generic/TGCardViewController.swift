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

  @IBOutlet weak var stickyBar: UIView!
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var cardWrapper: UIView!
  fileprivate weak var cardShadowView: UIView?
  
  // Dynamic constraints
  @IBOutlet weak var stickyBarHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var cardWrapperTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var cardWrapperHeightConstraint: NSLayoutConstraint!

  fileprivate var isVisible = false
  
  fileprivate var topCardView: TGCardView? {
    return cardWrapper.subviews.last as? TGCardView
  }

  fileprivate static let MinMapSpace: CGFloat = 50
  
  // MARK: - UIViewController
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Panner for dragging cards up and down
    let panGesture = UIPanGestureRecognizer()
    panGesture.addTarget(self, action: #selector(handle))
    panGesture.delegate = self
    cardWrapper.addGestureRecognizer(panGesture)

    // Hide sticky bar at first
    stickyBarHeightConstraint.constant = 0

    // Extend card at first
    cardWrapperTopConstraint.constant = extendedMinY
    cardWrapperHeightConstraint.constant = extendedMinY * -1
    
    roundCard()
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

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  // MARK: - Cards
  
  fileprivate var cards = [TGCard]()
  
  fileprivate let animationDuration = 0.4
  
  fileprivate var cardOverlap: CGFloat {
    return mapView.frame.height - cardWrapper.frame.minY
  }
  
  fileprivate var mapEdgePadding: UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 0, bottom: cardOverlap, right: 0)
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
    cardView.frame = cardWrapper.bounds
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
        let shadow = UIView(frame: cardWrapper.bounds)
        shadow.backgroundColor = .black
        shadow.alpha = 0
        cardWrapper.insertSubview(shadow, belowSubview: cardView)
        cardShadowView = shadow
      }
      
      UIView.animate(withDuration: animationDuration, animations: {
        cardView.frame = self.cardWrapper.bounds
        self.cardShadowView?.alpha = 0.15
      }, completion: whenDone)
      
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
      let shadow = UIView(frame: cardWrapper.bounds)
      shadow.backgroundColor = .black
      shadow.alpha = 0.15
      cardWrapper.insertSubview(shadow, belowSubview: topView)
      cardShadowView = shadow
    }
    
    UIView.animate(withDuration: animationDuration, animations: {
      topView.frame.origin.y = self.cardWrapper.frame.maxY
      self.cardShadowView?.alpha = 0
    }, completion: whenDone)
    
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
    
    value += TGCardViewController.MinMapSpace
    
    return value
  }
  
  fileprivate var collapsedMinY: CGFloat {
    return UIScreen.main.bounds.height * 4 / 5
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
    return self.stickyBarHeightConstraint.constant > 0
  }
  
  func showStickyBar(animated: Bool) {
    let stickyHeight: CGFloat = 50
    
    stickyBarHeightConstraint.constant = stickyHeight
    view.setNeedsUpdateConstraints()

    UIView.animate(withDuration: animated ? 0.25 : 0) {
      self.view.layoutIfNeeded()
    }
  }
  
  func hideStickyBar(animated: Bool) {
    self.stickyBarHeightConstraint.constant = 0
    view.setNeedsUpdateConstraints()

    UIView.animate(withDuration: animated ? 0.25 : 0) {
      self.view.layoutIfNeeded()
    }
  }
  
  // MARK: - Styling
  
  fileprivate func roundCard() {
    cardWrapper.layer.cornerRadius = 10
    cardWrapper.clipsToBounds = true
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
