//
//  ExampleChildStickyView.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 13/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class ExampleChildStickyView: UIView {

  static func instantiate() -> ExampleChildStickyView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("ExampleChildStickyView", owner: nil, options: nil)!.first as! ExampleChildStickyView
  }

}
