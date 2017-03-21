//
//  ExampleScrollStickyView.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 21/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class ExampleScrollStickyView: UIView {
  
  @IBOutlet weak var closeButton: UIButton!
  
  static func instantiate() -> ExampleScrollStickyView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("ExampleScrollStickyView", owner: self, options: nil)!.first as! ExampleScrollStickyView
  }
  
  
  fileprivate func didInit() {
    let button = UIButton(type: .system)
    button.setTitle("close", for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    addSubview(button)
    button.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    button.topAnchor.constraint(equalTo: topAnchor, constant: 20).isActive = true
    button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20).isActive = true
  }

}
