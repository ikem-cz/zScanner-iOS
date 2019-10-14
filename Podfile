platform :ios, '12.0'

inhibit_all_warnings!

def common_pods
    pod 'SnapKit'            # Easy constraints handling
    pod 'RxSwift', '~> 5'    # RxSwift
    pod 'RxCocoa', '~> 5'    # RxSwift
    pod 'RealmSwift'         # Database
    pod 'Fabric'             # Analytics
    pod 'Crashlytics'        # Crash reporting
    pod 'Firebase/Analytics' # Analytics
end

target 'zScanner' do
    use_frameworks!
    common_pods
end
