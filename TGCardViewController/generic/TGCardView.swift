//
//  TGCardView.swift
//  TGCardViewController
//
//  Created by Adrian Schoenig on 9/3/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

public class TGCardView: TGCornerView {
  
  /// Each card view needs a grab handle, which the controller
  /// might hide and show.
  @IBOutlet weak var grabHandle: TGGrabHandleView?
  
  /// The stack view that contains the label stack and the
  /// accessory view.
  @IBOutlet private weak var headerStack: UIStackView?
  
  /// The stack view that houses the title and subtitle labels.
  ///
  /// This outlet exists so that we can adjust the spacing between
  /// labels if necessary.
  @IBOutlet weak var labelStack: UIStackView?
  
  /// This is the constraint that connects the top of the header 
  /// stack view to the bottom of the grab handle. Together with
  /// the `headerStackBottomConstraint`, we can control the amount
  /// of white spaces when header isn't required.
  @IBOutlet weak var headerStackTopConstraint: NSLayoutConstraint?
  
  /// This is the constraint that connects the bottom of the header
  /// stack view to the top of the content view. See also
  /// `headerStackTopConstraint'.
  @IBOutlet weak var headerStackBottomConstraint: NSLayoutConstraint?
  
  /// Each card view needs a close button, which the card controller
  /// will add itself as a target to in order to pop the current card
  /// from the stack.
  @IBOutlet weak var closeButton: UIButton?
  
  /// This is the line separating the header and content parts of a
  /// card view.
  @IBOutlet weak var contentSeparator: UIView?
  
  /// Optional floating button.
  ///
  /// The button is only visible when the corresponding action closure
  /// is set.
  @IBOutlet weak var floatingButton: UIButton?
  
  /// Each card view needs a scroll view where the main content of the
  /// card goes. The card controller need access to it, in order to
  /// handling dragging the card up and down.
  @IBOutlet weak var contentScrollView: UIScrollView? {
    didSet {
      contentScrollView?.addObserver(self, forKeyPath: "contentOffset", options: [.new], context: nil)
    }
  }
  
  /// Each card view needs a place to display the card's title.
  @IBOutlet weak var titleLabel: UILabel!
  
  /// Each card view needs a place to display the card's subtitle.
  @IBOutlet weak var subtitleLabel: UILabel!
  
  /// Optional pager in which `contentScrollView` can be wrapped.
  ///
  /// - SeeAlso: `TGPageCardView` which relies on this.
  var pagingScrollView: UIScrollView?
  
  /// The height of the header part of the view, i.e., everything
  /// up to where `contentScrollView` starts.
  ///
  /// - Warning: Might not be accurate if the view hasn't been layed out.
  var headerHeight: CGFloat {
    guard let scrollView = contentScrollView else { return 0 }
    return scrollView.frame.minY
  }
  
  @IBOutlet private weak var accessoryWrapperView: UIView?
  
  /// Optional view beneath title + subtitle.
  var accessoryView: UIView? {
    get {
      return accessoryWrapperView?.subviews.first
    }
    set {
      guard let wrapper = accessoryWrapperView else {
        assertionFailure("Trying to set an accessory view but we don't have a wrapper for it")
        return
      }
      
      wrapper.subviews.forEach { $0.removeFromSuperview() }
      
      guard let view = newValue else {
        wrapper.isHidden = true
        headerStack?.spacing = 0
        return
      }
      
      wrapper.addSubview(view)
      view.snap(to: wrapper)
      wrapper.isHidden = false
      headerStack?.spacing = 4
      
      setNeedsUpdateConstraints()
    }
  }
  
  /// The closure to execute when the button is pressed.
  var onFloatingButtonPressed: (() -> Void)? {
    didSet {
      floatingButton?.isHidden = onFloatingButtonPressed == nil
    }
  }
  
  // MARK: - Configuration
  
  override public func awakeFromNib() {
    super.awakeFromNib()
    
    contentSeparator?.isHidden = true
    
    if let floatie = floatingButton {
      floatie.isHidden = true
      floatie.setImage(TGCardStyleKit.imageOfFloatingButton, for: .normal)
      floatie.setTitle(nil, for: .normal)      
    }
    
    // Here we set the minimum width and height to provide sufficient hit
    // target. The priority is lowered because we may need to hide the
    // button and in such case, stack view will reduce its size to zero,
    // hence creating conflicting constraints.
    let widthConstraint = closeButton?.widthAnchor.constraint(equalToConstant: 44)
    widthConstraint?.priority = .defaultHigh
    widthConstraint?.isActive = true
    
    let heightConstraint = closeButton?.heightAnchor.constraint(equalToConstant: 44)
    heightConstraint?.priority = .defaultHigh
    heightConstraint?.isActive = true
  }
  
  
  func configure(with card: TGCard, showClose: Bool, includeHeader: Bool) {
    titleLabel.text = includeHeader ? card.title : nil
    subtitleLabel.text = includeHeader ? card.subtitle : nil
    closeButton?.isHidden = !showClose
    labelStack?.spacing = includeHeader && card.subtitle != nil ? 3 : 0
    headerStackTopConstraint?.constant = includeHeader ? 8 : 0
    headerStackBottomConstraint?.constant = includeHeader ? 8 : 0
    
    if let action = card.floatingButtonAction {
      // TODO: We should add an accessibility label here
      // See: https://gitlab.com/SkedGo/tripgo-cards-ios/merge_requests/14#note_27632714
      floatingButton?.setTitle(nil, for: .normal)
      
      switch action.style {
      case .add:
        floatingButton?.setImage(TGCardStyleKit.imageOfFloatingButton, for: .normal)
      case .custom(let image):
        floatingButton?.setImage(image, for: .normal)
      }
      
      onFloatingButtonPressed = action.onPressed
    }
  }
  
  
  func allowContentScrolling(_ allowScrolling: Bool) {
    contentScrollView?.isScrollEnabled = allowScrolling
  }
  
  
  func headerHeight(for position: TGCardPosition) -> CGFloat {
    guard let scrollView = contentScrollView else {
      return 0
    }
    
    switch position {
    case .collapsed:
      var frame: CGRect
      
      if let wrapper = accessoryWrapperView,
         let accessory = accessoryView {
        // The frame of the accessory view in the coordinate system
        // of card view itself
        frame = wrapper.convert(accessory.frame, to: self)
      } else {
        // The frame of the scroll view in the coordinate system of
        // card view itself. Note, the scroll view may be embedded
        // inside another view, so we check for its superview here.
        frame = scrollView.superview?.convert(scrollView.frame, to: self) ?? scrollView.frame
      }
      
      if let handle = grabHandle {
        // If we have a grab handle, need to account for whether its hidden. If
        // its hideen, its space in the card view is reduced to 0.
        return handle.isHidden ? frame.minY - handle.frame.height : frame.minY
      } else {
        return frame.minY
      }
      
    default:
      return scrollView.superview?.convert(scrollView.frame, to: self).minY ?? scrollView.frame.minY
    }
  }
  
  @IBAction func floatingButtonTapped(_ sender: Any) {
    onFloatingButtonPressed?()
  }
  
  // MARK: - KVO
  
  deinit {
    contentScrollView?.removeObserver(self, forKeyPath: "contentOffset")
  }
  
  public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    guard
      let path = keyPath,
      path == "contentOffset",
      let separator = contentSeparator,
      let scroller = contentScrollView,
      scroller.isScrollEnabled == true
      else { return }
    
    separator.isHidden = scroller.contentOffset.y <= 0
  }
  
  
}
