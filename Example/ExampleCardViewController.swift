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
    super.init(nibName: "TGCardViewController", bundle: TGCardViewController.bundle)
  }
  
  override func viewDidLoad() {
    rootCard = ExampleRootCard()

    // This is useful for debugging positioning of things that might sneak
    // under the card, e.g., the map's attribution label
    rootCard?.style.backgroundColor = .systemBackground.withAlphaComponent(0.8)
    
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
