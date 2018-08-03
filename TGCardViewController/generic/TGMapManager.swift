//
//  TGMapManager.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import MapKit

public protocol TGCompatibleMapManager: class {
  
  func takeCharge(of mapView: UIView, edgePadding: UIEdgeInsets, animated: Bool)
  
  func cleanUp(_ mapView: UIView, animated: Bool)
  
  var edgePadding: UIEdgeInsets { get set }
}

open class TGMapManager: NSObject, TGCompatibleMapManager {
  public enum Zoom: Double {
    case road     = 5  // local level => how do I navigate on the road?
    case city     = 10 // can fit a city => where in the city are we?
    case country  = 15 // can fit a country => where in the world/in this country are we?
  }
  
  private struct MapState {
    let showsScale: Bool
    let showsUserLocation: Bool
    let showsTraffic: Bool
    
    init(for mapView: MKMapView) {
      showsScale = mapView.showsScale
      showsUserLocation = mapView.showsUserLocation
      showsTraffic = mapView.showsTraffic
    }
    
    func restore(for mapView: MKMapView) {
      mapView.showsScale = showsScale
      mapView.showsUserLocation = showsUserLocation
      mapView.showsTraffic = showsTraffic
    }
  }

  
  public var annotations = [MKAnnotation]() {
    didSet {
      guard let mapView = mapView else { return }
      mapView.removeAnnotations(oldValue)
      mapView.addAnnotations(annotations)
    }
  }
  
  /// How zoomed in/out the map should be when displaying the
  /// content the first time. Defaults to `.city`
  public var preferredZoomLevel: Zoom = .city
  
  public var edgePadding: UIEdgeInsets = .zero

  private var previousMapState: MapState?
  
  private var restoredMapRect: MKMapRect?

  public fileprivate(set) weak var mapView: MKMapView?
  
  public var isActive: Bool {
    return mapView != nil
  }
  
  public override init() {
  }
  
  public func takeCharge(of mapView: UIView, edgePadding: UIEdgeInsets, animated: Bool) {
    guard let mapView = mapView as? MKMapView else { preconditionFailure() }
    takeCharge(of: mapView, edgePadding: edgePadding, animated: animated)
  }
  
  /// Takes charge of the map view, adding the map manager's content
  ///
  /// - Parameters:
  ///   - mapView: Map view to take charge of
  ///   - edgePadding: Edge padding of the map view, e.g., if parts of the map view is
  /// obscured by other views.
  ///   - animated: If adding content should be animated
  open func takeCharge(of mapView: MKMapView, edgePadding: UIEdgeInsets, animated: Bool) {
    previousMapState = MapState(for: mapView)
    
    self.mapView = mapView
    mapView.delegate = self
    self.edgePadding = edgePadding
    
    mapView.addAnnotations(annotations)
    
    if let toRestore = restoredMapRect {
      mapView.setVisibleMapRect(toRestore, animated: false)
      restoredMapRect = nil
    } else {
      zoom(to: annotations, animated: animated)
    }
  }
  
  public func cleanUp(_ mapView: UIView, animated: Bool) {
    guard let mapView = mapView as? MKMapView else { preconditionFailure() }
    self.cleanUp(mapView, animated: animated)
  }
  
  /// Cleanes up the map view, removing the map manager's content
  /// and restoring the map view to a state similar to when 
  /// `takeCharge(of:)` was called.
  ///
  /// - Parameters:
  ///   - mapView: Map view to clean-up
  ///   - animated: If removing content should be animated
  open func cleanUp(_ mapView: MKMapView, animated: Bool) {
    guard mapView == self.mapView else {
      assertionFailure("Not the map view that we manage!")
      return
    }
    
    mapView.removeAnnotations(annotations)
    mapView.delegate = nil
    self.mapView = nil

    previousMapState?.restore(for: mapView)
  }
  
  public func zoom(to annotations: [MKAnnotation], animated: Bool) {
    mapView?.showAnnotations(annotations,
                             minimumZoomLevel: preferredZoomLevel.rawValue,
                             edgePadding: edgePadding,
                             animated: animated)
  }

  public func zoom(to mapRect: MKMapRect, animated: Bool) {
    mapView?.showMapRect(mapRect,
                         minimumZoomLevel: preferredZoomLevel.rawValue,
                         edgePadding: edgePadding,
                         animated: animated)
  }

  public var centerCoordinate: CLLocationCoordinate2D? {
    guard let mapView = mapView else { return nil }
    
    let visibleWidth = mapView.frame.width - edgePadding.left - edgePadding.right
    let visibleHeight = mapView.frame.height - edgePadding.top - edgePadding.bottom
    
    let centerPoint = CGPoint(x: edgePadding.left + visibleWidth / 2, y: edgePadding.top + visibleHeight / 2)
    return mapView.convert(centerPoint, toCoordinateFrom: mapView)
  }
  
  public func setCenter(_ coordinate: CLLocationCoordinate2D, animated: Bool) {
    mapView?.setCenter(coordinate, edgePadding: edgePadding, animated: animated)
  }
  
}


extension TGMapManager: MKMapViewDelegate {
  
}


extension MKMapView {
  
  func showAnnotations(_ annotations: [MKAnnotation],
                       minimumZoomLevel: Double,
                       edgePadding: UIEdgeInsets = .zero,
                       animated: Bool) {
    
    guard !annotations.isEmpty else { return }
    
    // Note: Using zero insets here as we'll respect the inspect already in the
    //       call below when setting the visible map rect - otherwise we adjust
    //       for it twice.
    let mapRect = mapRectThatFits(annotations.boundingMapRect, edgePadding: .zero)
    
    showMapRect(mapRect, minimumZoomLevel: minimumZoomLevel, edgePadding: edgePadding, animated: animated)
  }
  
  func showMapRect(_ mapRect: MKMapRect,
                   minimumZoomLevel: Double,
                   edgePadding: UIEdgeInsets = .zero,
                   animated: Bool) {
    
    guard !MKMapRectIsNull(mapRect) else { return }
    
    var mapRectToShow = mapRect
    
    if zoomLevel(of: mapRectToShow) < minimumZoomLevel {
      let center = MKMapPoint(x: MKMapRectGetMidX(mapRect), y: MKMapRectGetMidY(mapRect))
      mapRectToShow = self.mapRect(forZoomLevel: minimumZoomLevel, centeredOn: center)
    }
    
    setVisibleMapRect(mapRectToShow, edgePadding: edgePadding, animated: animated)
  }
  
  func setCenter(_ coordinate: CLLocationCoordinate2D,
                 edgePadding: UIEdgeInsets,
                 animated: Bool) {

    // Coordinate at the top left considering the edge padding
    let visibleTopLeft = convert(CGPoint(x: edgePadding.left, y: edgePadding.top), toCoordinateFrom: self)
    
    // Coordinate at the top left of the map, ignoring edge padding
    let unadjustedTopLeft = MKCoordinateForMapPoint(visibleMapRect.origin)
    
    // The new center is the desired centre minus half vector defining the difference of the two above
    let newCenter = CLLocationCoordinate2D(
      latitude: coordinate.latitude - (visibleTopLeft.latitude - unadjustedTopLeft.latitude) / 2,
      longitude: coordinate.longitude - (visibleTopLeft.longitude - unadjustedTopLeft.longitude) / 2
    )
    
    setCenter(newCenter, animated: animated)
  }
  
}

extension Array where Element: MKAnnotation {
  
  public var boundingMapRect: MKMapRect {
    return reduce(MKMapRectNull) { acc, annotation in
      let point = MKMapPointForCoordinate(annotation.coordinate)
      let miniRect = MKMapRect(origin: point, size: MKMapSize(width: 1, height: 1))
      return MKMapRectUnion(acc, miniRect)
    }
  }
  
}

extension Array where Element: MKOverlay {
  
  public var boundingMapRect: MKMapRect {
    return reduce(MKMapRectNull) { acc, overlay in
      return MKMapRectUnion(acc, overlay.boundingMapRect)
    }
  }
  
}

extension MKMapView {
  
  /// Zoom level in the 1-20 range. Where 1 is zoomed in. 20 is zoomed out.
  public var zoomLevel: Double {
    get {
      return zoomLevel(of: visibleMapRect)
    }
    set {
      setZoomLevel(newValue, animated: false)
    }
  }
  
  func setZoomLevel(_ zoomLevel: Double, edgePadding: UIEdgeInsets = .zero, animated: Bool) {
    let center = MKMapPointForCoordinate(centerCoordinate)
    let mapRect = self.mapRect(forZoomLevel: zoomLevel, centeredOn: center)
    setVisibleMapRect(mapRect, edgePadding: edgePadding, animated: animated)
  }
  
  fileprivate func zoomLevel(of mapRect: MKMapRect) -> Double {
    return log(mapRect.size.width / Double(frame.height)) / log(2) + 1
  }
  
  fileprivate func mapRect(forZoomLevel zoomLevel: Double, centeredOn center: MKMapPoint) -> MKMapRect {
    
    let ratio = pow(2, zoomLevel - 1)
    
    let viewRatio = Double(frame.width / frame.height)
    let width = Double(frame.height) * ratio
    let height = width / viewRatio
    
    return MKMapRect(origin: MKMapPoint(x: center.x - width / 2, y: center.y - height / 2),
                     size: MKMapSize(width: width, height: height))
  }
  
}
