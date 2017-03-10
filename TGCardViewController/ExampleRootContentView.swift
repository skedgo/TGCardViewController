//
//  ExampleRootContentView.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class ExampleRootContentView: UIView {

  @IBOutlet weak var addChildButton: UIButton!

  @IBOutlet weak var showTableButton: UIButton!
  
  static func instantiate() -> ExampleRootContentView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("ExampleRootContentView", owner: nil, options: nil)!.first as! ExampleRootContentView
  }  

}
