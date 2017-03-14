//
//  TGGrabHandleView.swift
//  TGCardViewController
//
//  Created by Kuan Lun Huang on 13/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TGGrabHandleView: UIView {

  override init(frame: CGRect) {
    super.init(frame: frame)
    didInit()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    didInit()
  }
  
  private func didInit() {
    let handle = UIView()
    handle.layer.cornerRadius = 3
    handle.backgroundColor = UIColor(white: 0.7, alpha: 1.0)
    handle.translatesAutoresizingMaskIntoConstraints = false
    addSubview(handle)
    
    handle.heightAnchor.constraint(equalToConstant: 5).isActive = true
    handle.widthAnchor.constraint(equalToConstant: 50).isActive = true
    handle.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    handle.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
    bottomAnchor.constraint(equalTo: handle.bottomAnchor, constant: 8).isActive = true
  }
}
