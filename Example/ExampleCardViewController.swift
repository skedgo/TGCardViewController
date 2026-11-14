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

  init() {
    super.init(nibName: "TGCardViewController", bundle: TGCardViewController.bundle)
  }
  
  required init(coder aDecoder: NSCoder) {
    // When loading from the storyboard we don't want to use the controller
    // as defined in the storyboard but instead use the TGCardViewController.xib
    super.init(nibName: "TGCardViewController", bundle: TGCardViewController.bundle)
  }
  
  override func viewDidLoad() {
    rootCard = ExampleRootCard(offersTabs: presentationStyle != .embedded)

    // This is useful for debugging positioning of things that might sneak
    // under the card, e.g., the map's attribution label
    // rootCard?.style.backgroundColor = .systemBackground.withAlphaComponent(0.5)
    
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

/// Shows the cards as the content of a tab. There they're embedded in the card
/// controller's view, as a system sheet would cover the tab bar.
class ExampleTabBarController: UITabBarController {
  
  init() {
    super.init(nibName: nil, bundle: nil)
    
    let cards = ExampleCardViewController()
    cards.presentationStyle = .embedded
    cards.tabBarItem = UITabBarItem(title: "Map", image: UIImage(systemName: "map"), tag: 0)
    
    let other = UIViewController()
    other.view.backgroundColor = .systemBackground
    other.tabBarItem = UITabBarItem(title: "Other", image: UIImage(systemName: "ellipsis.circle"), tag: 1)
    
    var close = UIButton.Configuration.borderedProminent()
    close.title = "Close tabs"
    let closeButton = UIButton(configuration: close, primaryAction: UIAction { [weak self] _ in
      self?.dismiss(animated: true)
    })
    closeButton.translatesAutoresizingMaskIntoConstraints = false
    other.view.addSubview(closeButton)
    NSLayoutConstraint.activate([
      closeButton.centerXAnchor.constraint(equalTo: other.view.centerXAnchor),
      closeButton.centerYAnchor.constraint(equalTo: other.view.centerYAnchor),
    ])
    
    viewControllers = [cards, other]
    modalPresentationStyle = .fullScreen
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}
