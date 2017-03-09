//
//  ExampleChildContentView.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class ExampleChildContentView: UIView {

  @IBOutlet weak var showStickyButton: UIButton!
  
  static func instantiate() -> ExampleChildContentView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("ExampleChildContentView", owner: nil, options: nil)!.first as! ExampleChildContentView
  }

}
