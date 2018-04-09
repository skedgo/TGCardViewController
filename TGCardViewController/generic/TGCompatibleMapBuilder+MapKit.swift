//
//  TGCompatibleMapBuilder+MapKit.swift
//  TGCardViewController
//
//  Created by Adrian Schönig on 07.04.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

public class TGMapKitBuilder: TGCompatibleMapBuilder {
  
  public var askForLocationPermissions: ((_ completion: @escaping (Bool) -> Void) -> Void)?
  
  public func buildMapView() -> UIView {
    return MKMapView()
  }
  
  public func buildUserTrackingButton(for mapView: UIView) -> UIView? {
    guard #available(iOS 11.0, *), askForLocationPermissions != nil else { return nil }
    guard let mapView = mapView as? MKMapView else { preconditionFailure() }
    
    let background = UIView()
    background.isUserInteractionEnabled = true
    background.widthAnchor.constraint(equalToConstant: 44).isActive = true
    background.heightAnchor.constraint(equalToConstant: 44).isActive = true
    
    let tracker = MKUserTrackingButton(mapView: mapView)
    tracker.translatesAutoresizingMaskIntoConstraints = false
    background.addSubview(tracker)
    
    tracker.centerXAnchor.constraint(equalTo: background.centerXAnchor).isActive = true
    tracker.centerYAnchor.constraint(equalTo: background.centerYAnchor).isActive = true
    
    // MKUserTrackingButton in iOS 11 just goes into a dumb spinner mode, if
    // no permissions are granted. To work around this, we disable it and instead
    // intercept taps.
    // The way we handle the DisposeBag might(?) introduce a retain cycle, but
    // this only exists until you provide access to the current location.
    if CLLocationManager.authorizationStatus() == .notDetermined {
      tracker.isUserInteractionEnabled = false
      let tapper = UITapGestureRecognizer()
      tapper.addTarget(self, action: #selector(trackerButtonPressed))
      background.addGestureRecognizer(tapper)
    }
    
    return background
    
  }
  
  @objc
  private func trackerButtonPressed(_ recogniser: UITapGestureRecognizer) {
    guard #available(iOS 11.0, *) else { return }
    guard let tracker = recogniser.view?.subviews.first as? MKUserTrackingButton else {
      preconditionFailure()
    }
    
    CLLocationManager().requestWhenInUseAuthorization()
    askForLocationPermissions? { success in
      guard success else { return }
      tracker.isUserInteractionEnabled = true
      tracker.mapView?.userTrackingMode = .follow
    }
    
  }

}
