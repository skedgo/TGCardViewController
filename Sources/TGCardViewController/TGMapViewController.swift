//
//  TGMapViewController.swift
//  TGCardViewController
//
//  Created by Adrian Schönig on 31/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

/// A container view controller for the map view, to set its safe area separately from the main TGCardVC
class TGMapViewController: UIViewController {
  
  var builder: TGCompatibleMapBuilder = TGMapKitBuilder()
  
  var mapView: UIView! { view }
  
  override func loadView() {
    let mapView = builder.buildMapView()
    self.view = mapView
  }
  
  var isUserInteractionEnabled: Bool {
    get { mapView.isUserInteractionEnabled }
    set {
      mapView.isUserInteractionEnabled = newValue

      // This is a weird but functioning way of making the map not accessible
      // in a reliable way
      mapView.accessibilityFrame = newValue ? mapView.frame : .zero
      UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }
  }
  
}
