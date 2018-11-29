
Pod::Spec.new do |spec|
  spec.name         = "BCPhotoRecord"
  spec.version      = "1.0.7"
  spec.summary      = "拍照和拍短视频"
  spec.description  = "拍照和拍摄短视频"
  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author       = { "Bro.chao" => "272152741@qq.com" }
  spec.homepage     = "https://github.com/chaorenios/BCPhotoRecord"
  spec.source       = { :git => "https://github.com/chaorenios/BCPhotoRecord.git", :tag => "#{spec.version}" }
  
  spec.swift_version  = "4.2"
  spec.platform       = :ios, "10.0"

  spec.framework    = "UIKit"
  spec.source_files = "BCPhotoRecord/*"
  spec.resource_bundles = {"BCPhotoRecord" => "BCPhotoRecord/images/*"}
end
