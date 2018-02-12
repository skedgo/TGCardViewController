//
//  ExampleChildContentView.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

class ExampleChildContentView: UIView {

  @IBOutlet weak var showStickyButton: UIButton!
  @IBOutlet weak var showStickyCreditsButton: UIButton!
  
  static func instantiate() -> ExampleChildContentView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("ExampleChildContentView", owner: nil, options: nil)!.first as! ExampleChildContentView
  }

}
