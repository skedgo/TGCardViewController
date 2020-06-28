//
//  ExampleAccessoryView.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 4/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

class ExampleAccessoryView: UIView {
  
  static func instantiate() -> ExampleAccessoryView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("ExampleAccessoryView", owner: nil, options: nil)!.first as! ExampleAccessoryView
  }

}
