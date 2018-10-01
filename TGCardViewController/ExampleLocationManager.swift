//
//  ExampleLocationManager.swift
//  Example
//
//  Created by Adrian Schönig on 01.10.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import CoreLocation

public class ExampleLocationManager: NSObject {
  
  public static let shared = ExampleLocationManager()
  
  private let coreLocationManager: CLLocationManager
  
  private var permissionsCompletionHandler: ((Bool) -> Void)?
  
  private override init() {
    coreLocationManager = CLLocationManager()
    super.init()
    
    coreLocationManager.delegate = self
  }
  
  public func askForPermissions(completion: @escaping (Bool) -> Void) {
    permissionsCompletionHandler = completion
    
    coreLocationManager.requestWhenInUseAuthorization()
  }
  
}

extension ExampleLocationManager: CLLocationManagerDelegate {
  public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    permissionsCompletionHandler?(status == .authorizedWhenInUse || status == .authorizedAlways)
  }
}
