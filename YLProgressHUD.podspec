#
#  Be sure to run `pod spec lint YLProgressHUD.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "YLProgressHUD"
  spec.version      = "0.0.4"
  spec.summary      = "macos开发，hud显示"
  spec.homepage     = "https://github.com/yulong000/YLProgressHUD.git"
  spec.license      = "MIT"
  spec.author       = { "魏宇龙" => "weiyulong1987@163.com" }
  spec.platform     = :macos, "10.14"
  spec.source       = { :git => "https://github.com/yulong000/YLProgressHUD.git", :tag => "#{spec.version}" }
  spec.source_files = "YLProgressHUD/YLProgressHUD/*.{h,m}",
  spec.resource     = "YLProgressHUD/YLProgressHUD/YLProgressHUD.bundle"
  spec.public_header_files = "YLProgressHUD/YLProgressHUD/YLProgressHUD.h"
  spec.requires_arc = true

end


# 升级时  1.add tag
#        2.push tag
#        3.pod trunk push YLProgressHUD.podspec
