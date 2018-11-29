#
#  Be sure to run `pod spec lint BCPhotoRecord.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "BCPhotoRecord"
  spec.version      = "1.0.3"
  spec.summary      = "拍照和拍短视频"
  spec.swift_version = "4.2"

  spec.description  =  <<-DESC
  拍照和拍摄短视频
                    DESC

  spec.homepage     = "https://github.com/chaorenios/BCPhotoRecord"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "Bro.chao" => "272152741@qq.com" }
  spec.platform     = :ios, "10.0"
  spec.source       = { :git => "https://github.com/chaorenios/BCPhotoRecord.git", :tag => "#{spec.version}" }
  spec.source_files  = "BCPhotoRecord/**/*"
  spec.framework  = "UIKit"
  spec.resource_bundles = { 'images' => ['BCPhotoRecord/images/*']}

end
