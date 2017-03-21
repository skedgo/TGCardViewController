//
//  ExampleScrollStickyView.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 21/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class ExampleScrollStickyView: UIView {
  
  @IBOutlet weak var previousButton: UIButton!
  @IBOutlet weak var nextButton: UIButton!
  @IBOutlet weak var closeButton: UIButton!
  
  static func instantiate() -> ExampleScrollStickyView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("ExampleScrollStickyView", owner: self, options: nil)!.first as! ExampleScrollStickyView
  }

}
