platform :ios, '13.0'

inhibit_all_warnings!

def common_pods
    pod 'SnapKit'              # Easy constraints handling
    pod 'RxSwift', '~> 5'      # RxSwift
    pod 'RxCocoa', '~> 5'      # RxSwift
    pod 'RealmSwift'           # Database
    pod 'Firebase/Crashlytics' # Crashlytics
    pod 'Firebase/Analytics'   # Analytics
    pod 'TUSKit'               # Large file upload
    pod 'UPCarouselFlowLayout' # Horizontal picker
end

target 'zScanner' do
    use_frameworks!
    common_pods
end
