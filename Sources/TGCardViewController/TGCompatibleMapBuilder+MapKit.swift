//
//  TGCompatibleMapBuilder+MapKit.swift
//  TGCardViewController
//
//  Created by Adrian Schönig on 07.04.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

/// A map builder that uses Apple's MapKit framework.
///
/// Uses an instance of `MKMapView` as the shared map, supports compass button, and user tracking
/// button. However, to enable the user tracking button, make sure to provide a block to
/// ``askForLocationPermissions``.
public class TGMapKitBuilder: TGCompatibleMapBuilder {
  public init(askForLocationPermissions: ((_ completion: @escaping (Bool) -> Void) -> Void)? = nil) {
    self.askForLocationPermissions = askForLocationPermissions
  }
  
  public var askForLocationPermissions: ((_ completion: @escaping (Bool) -> Void) -> Void)?
  
  private var compassObservation: NSKeyValueObservation?
  
  /// The default map rect to use on start-up. If not supplied, it will use default behaviour from `MKMapView`
  /// which focuses on the user's country.
  public var startOnMapRect: MKMapRect = .null
  
  /// Uses MapKit's `MKMapView`
  public func buildMapView() -> UIView {
    let mapView = MKMapView()
    if !startOnMapRect.isNull {
      mapView.setVisibleMapRect(startOnMapRect, animated: false)
    }
    return mapView
  }

  /// Uses MapKit's `MKCompassButton`
  public func buildCompassButton(for mapView: UIView) -> UIView? {
    guard let mapView = mapView as? MKMapView else { preconditionFailure() }
    mapView.showsCompass = false
    
    let background = UIView()
    background.isUserInteractionEnabled = true
    background.widthAnchor.constraint(equalToConstant: 44).isActive = true
    background.heightAnchor.constraint(equalToConstant: 44).isActive = true

    let compass = MKCompassButton(mapView: mapView)
    compass.translatesAutoresizingMaskIntoConstraints = false
    background.addSubview(compass)
    
    compass.centerXAnchor.constraint(equalTo: background.centerXAnchor).isActive = true
    compass.centerYAnchor.constraint(equalTo: background.centerYAnchor).isActive = true
    
    // The compass fades in and out. We don't want a blank space for it them, so
    // we observe it's hidden property and then update the height of its wrapper
    background.isHidden = true
    compassObservation = compass.observe(\MKCompassButton.isHidden) { compass, _ in
      UIView.animate(withDuration: 0.25) {
        background.isHidden = compass.isHidden
      }
    }
    
    if #available(iOS 13.4, *) {
      background.addInteraction(UIPointerInteraction())
    }
    
    return background
  }

  /// Uses MapKit's `MKUserTrackingButton`
  public func buildUserTrackingButton(for mapView: UIView) -> UIView? {
    guard askForLocationPermissions != nil else { return nil }
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
      Self.updateTracker(tracker, enabled: false)
      let tapper = UITapGestureRecognizer()
      tapper.addTarget(self, action: #selector(trackerButtonPressed))
      background.addGestureRecognizer(tapper)
    }
    
    if #available(iOS 13.4, *) {
      background.addInteraction(UIPointerInteraction())
    }
    
    return background
  }
  
  @objc
  private func trackerButtonPressed(_ recogniser: UITapGestureRecognizer) {
    guard let tracker = recogniser.view?.subviews.first as? MKUserTrackingButton else {
      preconditionFailure()
    }
    
    // authorisation might have since been granted
    guard CLLocationManager.authorizationStatus() == .notDetermined else {
      Self.updateTracker(tracker, enabled: true)
      tracker.mapView?.userTrackingMode = .follow
      return
    }
    
    askForLocationPermissions? { success in
      guard success else { return }
      Self.updateTracker(tracker, enabled: true)
      tracker.mapView?.userTrackingMode = .follow
    }
  }
  
  private static func updateTracker(_ tracker: MKUserTrackingButton, enabled: Bool) {
    tracker.isUserInteractionEnabled = enabled
    
    // required on iOS 13 as the button has a little button within it
    tracker.subviews.compactMap { $0 as? UIButton }.forEach { $0.isUserInteractionEnabled = enabled }
  }

}
