//
//  NewDocumentVideoSelectionViewController.swift
//  zScanner
//
//  Created by Jan Provazník on 12/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift
import MobileCoreServices

protocol NewDocumentPhotosCoordinator: BaseCoordinator {
    func savePhotos(_ photos: [UIImage])
    func showNextStep()
}

class NewDocumentVideosSelectionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
//func videoSnapshot(filePathLocal: String) -> UIImage? {
//
//    let vidURL = URL(fileURLWithPath:filePathLocal as String)
//    let asset = AVURLAsset(url: vidURL)
//    let generator = AVAssetImageGenerator(asset: asset)
//    generator.appliesPreferredTrackTransform = true
//
//    let timestamp = CMTime(seconds: 1, preferredTimescale: 60)
//
//    do {
//        let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
//        return UIImage(cgImage: imageRef)
//    }
//    catch let error as NSError
//    {
//        print("Image generation failed with error \(error)")
//        return nil
//    }
//}
