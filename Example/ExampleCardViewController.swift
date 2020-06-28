//
//  ViewController.swift
//  ExampleCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import MapKit

import TGCardViewController

class ExampleCardViewController: TGCardViewController {

  required init(coder aDecoder: NSCoder) {
    // When loading from the storyboard we don't want to use the controller
    // as defined in the storyboard but instead use the TGCardViewController.xib
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))
  }
  
  override func viewDidLoad() {
    rootCard = ExampleRootCard()
    
    navigationButtonsAreSpringLoaded = true
    
    #if targetEnvironment(macCatalyst)
    mode = .sidebar
    #endif
    
    builder.askForLocationPermissions = ExampleLocationManager.shared.askForPermissions

    super.viewDidLoad()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

}
