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
  
  // Dynamic constraints
  @IBOutlet weak var stickyBarHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var cardWrapperHeightConstraint: NSLayoutConstraint!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  // MARK: - Cards
  
  fileprivate var cards = [TGCard]()
  
  func push(_ card: TGCard, animated: Bool = true) {
    var top = card
    
    top.controller = self
    cards.append(top)
    
    let view = top.buildView(showClose: cards.count > 1)
    view.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: cardWrapper.frame.size)
    view.closeButton.addTarget(self, action: #selector(closeTapped(sender:)), for: .touchUpInside)
    
    cardWrapper.addSubview(view)
  }
  
  func pop(animated: Bool = true) {
    guard var top = cards.last, let topView = cardWrapper.subviews.last else {
      print("Nothing to pop")
      return
    }
    
    top.controller = nil
    cards.remove(at: cards.count - 1)
    
    topView.removeFromSuperview()
  }
  
  @objc
  func closeTapped(sender: Any) {
    pop()
  }

  // MARK: - Sticky bar at the top
  
  func showStickyBar(animated: Bool) {
    UIView.animate(withDuration: 0.25) {
      self.stickyBarHeightConstraint.constant = 50
    }
  }
  
  func hideStickyBar(animated: Bool) {
    UIView.animate(withDuration: 0.25) {
      self.stickyBarHeightConstraint.constant = 0
    }
  }
  

}
