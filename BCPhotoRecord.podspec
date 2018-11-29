
Pod::Spec.new do |spec|
  spec.name         = "BCPhotoRecord"
  spec.version      = "1.0.4"
  spec.summary      = "拍照和拍短视频"
  spec.description  = "拍照和拍摄短视频"
  spec.homepage     = "https://github.com/chaorenios/BCPhotoRecord"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Bro.chao" => "272152741@qq.com" }
  spec.platform     = :ios, "10.0"
  spec.source       = { :git => "https://github.com/chaorenios/BCPhotoRecord.git", :tag => "#{spec.version}" }
  spec.framework  = "UIKit"

  spec.swift_version = "4.2"
  spec.platform     = :ios, "10.0"
  spec.ios.deployment_target = '10.0'
end
