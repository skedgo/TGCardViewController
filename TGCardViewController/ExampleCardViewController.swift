//
//  ViewController.swift
//  ExampleCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import MapKit

class ExampleCardViewController: TGCardViewController {

  required init(coder aDecoder: NSCoder) {
    super.init(nibName: "TGCardViewController", bundle: .main)
  }
  
//  override func awakeAfter(using aDecoder: NSCoder) -> Any? {
//    // The super classes XIB file defines the whole structure
//    return TGCardViewController(nibName: "TGCardViewController", bundle: .main) as Any
//  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    push(TGPlainCard(title: "Root"), animated: false)
    push(TGPlainCard(title: "Child"), animated: false)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}


