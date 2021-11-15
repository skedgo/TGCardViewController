//
//  TGCompatibleMapBuilder.swift
//  TGCardViewController
//
//  Created by Adrian Schönig on 07.04.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// A builder that provides the view which powers the map component of TGCardViewController.
///
/// You can use any mapping UI library as long as you provide a builder for it and then make sure
/// your ``TGMapManager`` subclasses handle it properly.
///
/// For an example, see ``TGMapKitBuilder`` which uses Apple's MapKit.
public protocol TGCompatibleMapBuilder {
  
  /// Creates a new map view, which will be the map view for the card view controller
  ///
  /// - Returns: New instance of a map view
  func buildMapView() -> UIView
  
  func buildUserTrackingButton(for mapView: UIView) -> UIView?

  func buildCompassButton(for mapView: UIView) -> UIView?

  /// If you want a current location button on the map, provide this method which will be
  /// called if the user didn't yet grant access to the current location and the current
  /// location button is pressed.
  /// Your function should ask for permissions and then call the block indicating whether
  /// the user did grant permissions.
  var askForLocationPermissions: ((_ completion: @escaping (Bool) -> Void) -> Void)? { get set }

}

extension TGCompatibleMapBuilder {
  public func buildUserTrackingButton(for mapView: UIView) -> UIView? {
    return nil
  }
  
  public func buildCompassButton(for mapView: UIView) -> UIView? {
    return nil
  }
}
