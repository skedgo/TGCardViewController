//
//  MockupImageContentView.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 16/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class MockupImageContentView : UIView {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
  @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
  
  static func instantiate() -> MockupImageContentView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("MockupImageContentView", owner: nil, options: nil)!.first as! MockupImageContentView
  }
  
}
