//
//  ExampleChildCard.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import SwiftUI
import UIKit
import MapKit

import TGCardViewController

class ExampleChildCard : TGPlainCard {
  
  private let titleHandler: TitleHandler
  var titleHost: UIHostingController<TitleView>
  var contentHost: UIHostingController<ContentView>
  
  init() {
    let handler = TitleHandler()
    self.titleHandler = handler
    let titleHost = UIHostingController(rootView: TitleView(handler: handler))
    titleHost.view.backgroundColor = .clear
    self.titleHost = titleHost
    
    let contentHost = UIHostingController(rootView: ContentView())
    self.contentHost = contentHost
    
    super.init(
      title: .custom(titleHost.view, dismissButton: nil),
      contentView: contentHost.view,
      extended: true,
      mapManager: TGMapManager.sydney
    )
    
    handler.onClose = { [weak self] in
      self?.controller?.pop()
    }
    
    self.topMapToolBarItems = [UIButton.dummyDetailDisclosureButton(), UIButton.dummyDetailDisclosureButton()]
    self.bottomMapToolBarItems = [] // This forces an empty bottom floating view
  }
  
  override func shouldToggleSeparator(show: Bool, offset: CGFloat) -> Bool {
    titleHandler.scrollOffset = offset
    return false
  }
  
  override func willAdjustContentAlpha(_ value: CGFloat) {
    titleHandler.contentAlpha = value
  }
  
}

private class TitleHandler: ObservableObject {
  var onClose: () -> Void = {}
  
  @Published var scrollOffset: CGFloat = 0
  @Published var contentAlpha: CGFloat = 1
  
  init() {}
}

struct TitleView: View {
  @ObservedObject fileprivate var handler: TitleHandler
  
  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text("A Child View")
          .font(.largeTitle)
        Text("With a subtitle")
          .font(.headline)
      }
      
      Spacer()
      
      Button {
        handler.onClose()
      } label: {
        Image(systemName: "xmark.circle.fill")
      }
    }
    .padding(.top, -10)
    .padding(.horizontal)
    .padding(.bottom)
    .foregroundColor(handler.contentAlpha < 1 ? .black : Color.init(white: 1.0 - fabs(handler.scrollOffset) / 20))
//    .foregroundStyle(.white)
    .background {
      Rectangle()
//        .foregroundStyle(.clear)
//        .overlay(
//          Gradient(stops: [
//            .init(color: .black.opacity(0.7), location: 0),
//            .init(color: .black.opacity(0), location: 0.3),
//          ])
//        )
        .foregroundStyle(.background)
        .opacity(handler.contentAlpha < 1 ? 1 : fabs(handler.scrollOffset) / 20)
        .offset(y: -20)
        .padding(.bottom, -16)
    }
  }
}

struct ContentView: View {
  var body: some View {
    VStack {
      Image("erlking")
        .resizable()
        .scaledToFit()
        .overlay(
          Gradient(stops: [
            .init(color: .black.opacity(0.7), location: 0),
            .init(color: .black.opacity(0), location: 0.3),
            .init(color: .black.opacity(0), location: 0.8),
            .init(color: .black.opacity(0.7), location: 1),
          ])
        )
      
      Text("""
        Who rides there so late through the night dark and drear?
        The father it is, with his infant so dear;
        He holdeth the boy tightly clasp'd in his arm,
        He holdeth him safely, he keepeth him warm.

        "My son, wherefore seek'st thou thy face thus to hide?"
        "Look, father, the Erl-King is close by our side!
        Dost see not the Erl-King, with crown and with train?"
        "My son, 'tis the mist rising over the plain."

        "Oh, come, thou dear infant! oh come thou with me!
        For many a game I will play there with thee;
        On my strand, lovely flowers their blossoms unfold,
        My mother shall grace thee with garments of gold."

        "My father, my father, and dost thou not hear
        The words that the Erl-King now breathes in mine ear?"
        "Be calm, dearest child, 'tis thy fancy deceives;
        'Tis the sad wind that sighs through the withering leaves."

        "Wilt go, then, dear infant, wilt go with me there?
        My daughters shall tend thee with sisterly care;
        My daughters by night their glad festival keep,
        They'll dance thee, and rock thee, and sing thee to sleep."

        "My father, my father, and dost thou not see,
        How the Erl-King his daughters has brought here for me?"
        "My darling, my darling, I see it aright,
        'Tis the aged grey willows deceiving thy sight."

        "I love thee, I'm charm'd by thy beauty, dear boy!
        And if thou'rt unwilling, then force I'll employ."
        "My father, my father, he seizes me fast,
        For sorely the Erl-King has hurt me at last."

        The father now gallops, with terror half wild,
        He grasps in his arms the poor shuddering child;
        He reaches his courtyard with toil and with dread, –
        The child in his arms finds he motionless, dead.
        """)
      .padding()
    }
  }
}
