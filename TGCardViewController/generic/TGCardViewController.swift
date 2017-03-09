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
    cards.append(card)
    
    let view = card.buildView()
    cardWrapper.addSubview(view)
  }
  
  func pop(animated: Bool = true) {
    guard cards.count > 0 else {
      print("Nothing to pop")
      return
    }
    
    cards.remove(at: cards.count - 1)
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
