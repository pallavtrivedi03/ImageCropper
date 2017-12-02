//
//  ProfilePicVC.swift
//  ImageCropper
//
//  Created by Pallav Trivedi on 02/12/17.
//  Copyright © 2017 Pallav Trivedi. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import Photos

class ProfilePicVC: UIViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    //MARK: Action Methods
    @IBAction func didClickOnEditImage(_ sender: UIButton)
    {
        let alertViewController = UIAlertController(title: "", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        //Choose from Library
        let chooseFromLibraryAction = UIAlertAction(title: "Choose From Library", style: UIAlertActionStyle.default, handler: {[weak self] (alertAction) -> Void in
            self?.presentPickerViewForString( "Choose From Library")
        })
        alertViewController.addAction(chooseFromLibraryAction)
        
        let cancelAction = UIAlertAction(title:  "Cancel", style: UIAlertActionStyle.cancel, handler: { (alertAction) -> Void in
            
        })
        alertViewController.addAction(cancelAction)
        
        // Take A Photo
        /*if UIImagePickerController.isCameraDeviceAvailable( UIImagePickerControllerCameraDevice.front) || UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice.rear)
         {
         let takeAPhotoAction = UIAlertAction(title: NSLocalizedString("Take A Photo", comment: "Take A Photo"), style: UIAlertActionStyle.default, handler: {[weak self] (alertAction) -> Void in
         self!.presentPickerViewForString(NSLocalizedString("Take A Photo", comment: "Take A Photo"))
         })
         alertViewController.addAction(takeAPhotoAction)
         }*/
        
        self.present(alertViewController, animated: true, completion: nil)
    }
    
    //MARK: Helper Methods
    private func presentPickerViewForString (_ pickerString:String)
    {
        let imagePicker         = UIImagePickerController()
        imagePicker.delegate    = self
        
        if pickerString == "Take A Photo"
        {
            let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
            if status == AVAuthorizationStatus.denied || status == AVAuthorizationStatus.restricted {
                let alertView =  UIAlertController(title: "", message: NSLocalizedString("CAMERA", comment: "Please go to iOS Settings > Privacy > Camera to allow access to save photo in your library."), preferredStyle: UIAlertControllerStyle.alert)
                
                let action = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.default, handler: { (alertAction) in
                    
                })
                alertView.addAction(action)
                
                self.present(alertView, animated: true, completion: nil)
                
            }else {
                imagePicker.sourceType  = UIImagePickerControllerSourceType.camera
            }
        }else {
            imagePicker.sourceType  = UIImagePickerControllerSourceType.photoLibrary
        }
        imagePicker.allowsEditing = false;
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    private func showCropperView(selectedImage:UIImage)
    {
        let imageCropperView = ImageCropperView().loadNib() as! ImageCropperView
        imageCropperView.frame = self.view.frame
        imageCropperView.selectedImageView.image = selectedImage
        imageCropperView.delegate = self
        self.view.addSubview(imageCropperView)
    }
}

extension ProfilePicVC:ImageCropperDelegate
{
    func didClickOnCropImage(image: UIImage)
    {
        profileImageView.image = image
    }
}

extension ProfilePicVC :  UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        let status = PHPhotoLibrary.authorizationStatus()
        if (picker.sourceType  == UIImagePickerControllerSourceType.camera) {
            if let image =  info[UIImagePickerControllerOriginalImage]  as? UIImage {
                DispatchQueue.main.async {
                    //self?.profileImageView.image = image
                    self.showCropperView(selectedImage: image)
                }
            }
        }else {
            if status == PHAuthorizationStatus.notDetermined {
                PHPhotoLibrary.requestAuthorization({ (status) in
                    self.setimageFromAsset(info[UIImagePickerControllerReferenceURL] as! URL)
                })
            }else if status == PHAuthorizationStatus.denied {
                let alertView =  UIAlertController(title: "", message: NSLocalizedString("PHOTOS", comment: "Please go to iOS Settings > Privacy > Photo to allow access to save photo in your library."), preferredStyle: UIAlertControllerStyle.alert)
                
                let action = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.default, handler: { (alertAction) in
                    
                })
                alertView.addAction(action)
                
                self.present(alertView, animated: true, completion: nil)
                
            }else {
                self.setimageFromAsset(info[UIImagePickerControllerReferenceURL] as! URL)
            }
        }
    }
    
    private func setimageFromAsset(_ assetURL: URL) {
        PHAsset.imageFromAsset(nsurl: assetURL, imageReturn: {[weak self] (image) -> (Void) in
            DispatchQueue.main.async {
                //self?.profileImageView.image = image
                self?.showCropperView(selectedImage: image!)
            }
        })
        
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    
}

extension PHAsset {
    class func imageFromAsset(nsurl: URL, imageReturn: @escaping ((UIImage?) -> (Swift.Void))) {
        let asset = PHAsset.fetchAssetWithALAssetURL(alURL: nsurl)
        let targetSize = CGSize(width: 300, height: 300)
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        
        PHImageManager.default().requestImage(for: asset!, targetSize: targetSize, contentMode: PHImageContentMode.aspectFit, options: options, resultHandler: { (result, info) in
            imageReturn(result)
        })
    }
    
    class func fetchAssetWithALAssetURL (alURL: URL) -> PHAsset? {
        
        let optionsForFetch = PHFetchOptions()
        optionsForFetch.includeHiddenAssets = true
        
        let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [alURL], options: optionsForFetch)
        if fetchResult.count > 0 {
            return fetchResult[0]
        }
        return nil
    }
}
