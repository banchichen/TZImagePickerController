Pod::Spec.new do |s|
  s.name         = "TZImagePickerController"
  s.version      = "3.8.12"
  s.summary      = "A clone of UIImagePickerController, support picking multiple photos、original photo and video"
  s.homepage     = "https://github.com/banchichen/TZImagePickerController"
  s.license      = "MIT"
  s.author       = { "banchichen" => "tanzhenios@foxmail.com" }
  s.platform     = :ios
  s.ios.deployment_target = "10.0"
  s.source       = { :git => "https://github.com/banchichen/TZImagePickerController.git", :tag => "3.8.12" }
  s.requires_arc = true
  s.resource_bundles = {
    'TZImagePickerControllerPrivacy' => ['TZImagePickerControllerFramework/PrivacyInfo.xcprivacy']
  }
  
  s.subspec 'Basic' do |b|
    b.resources    = "TZImagePickerController/Resources/*.bundle"
    b.source_files = "TZImagePickerController/TZImagePickerController/*.{h,m}"
  end
  
  s.subspec 'Location' do |l|
    l.source_files = 'TZImagePickerController/Location/*.{h,m}'
  end
  
  s.frameworks   = "Photos", "PhotosUI"
end
