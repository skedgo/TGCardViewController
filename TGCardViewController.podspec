#
#  Be sure to run `pod spec lint TGCardViewController.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#

Pod::Spec.new do |s|

  s.name         = "TGCardViewController"
  s.version      = "1.1"
  s.summary      = "Card-based view controller for mapping apps"

  s.description  = <<-DESC
    A view controller with a map and a stack of cards. Cards can work both
    as a hierarchy like a navigation controller and as a list like a page
    controller - or a combination thereof.
                   DESC

  s.homepage     = "https://gitlab.com/SkedGo/iOS/tripgo-cards-ios"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  s.license      = 'Apache License, Version 2.0'


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  s.authors             = { "Adrian Schoenig": "adrian@skedgo.com",
                            "Brian Huang": "brian@skedgo.com" }

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #

  s.platform     = :ios, "10.3"
  s.swift_version = '5.1'

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  # s.source       = { git: "." }
  s.source       = { :git => "https://gitlab.com/SkedGo/iOS/tripgo-cards-ios.git", :tag => "v#{s.version}" }


  # ――― Source Code + Resources ―――――――――――――――――――――――――――――――――――――――――――――――――― #
  #

  s.source_files  = "TGCardViewController/generic/**/*.swift"
  s.resources = "TGCardViewController/generic/**/*.xib"

end
