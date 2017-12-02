//
//  ImageCropperView.swift
//  Modules
//
//  Created by Pallav Trivedi on 30/11/17.
//  Copyright © 2017 Pallav Trivedi. All rights reserved.
//

import UIKit

protocol ImageCropperDelegate
{
    func didClickOnCropImage(image:UIImage)
}

class ImageCropperView: UIView
{
    
    @IBOutlet weak var aspectRatioConstraint: NSLayoutConstraint!
    @IBOutlet weak var cropAreaView: CropperView!
    @IBOutlet weak var selectedImageView: UIImageView!
    var delegate:ImageCropperDelegate?
    @IBOutlet weak var scrollView: UIScrollView!{
        didSet{
            scrollView.delegate = self
            scrollView.minimumZoomScale = 1.0
            scrollView.maximumZoomScale = 10.0

        }
    }

    var cropArea:CGRect{
        get{
            let factor = selectedImageView.image!.size.width/self.frame.width
            let scale = 1/scrollView.zoomScale
            let imageFrame = selectedImageView.imageFrame()
            let x = (scrollView.contentOffset.x + cropAreaView.frame.origin.x - imageFrame.origin.x) * scale * factor
            let y = (scrollView.contentOffset.y + cropAreaView.frame.origin.y - imageFrame.origin.y) * scale * factor
            let width = cropAreaView.frame.size.width * scale * factor
            let height = cropAreaView.frame.size.height * scale * factor
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }
    
    
    //MARK: Helper Methods
    func changeAspectRatio(ratio:Float)
    {
        let newConstraint = self.aspectRatioConstraint.constraintWithMultiplier(CGFloat(ratio))
        self.removeConstraint(self.aspectRatioConstraint)
        self.aspectRatioConstraint = newConstraint
        self.addConstraint(self.aspectRatioConstraint)
        self.layoutIfNeeded()
        
    }
    
    //MARK: Action Methods
    @IBAction func didClickOnCropButton(_ sender: UIButton)
    {
        let croppedCGImage = selectedImageView.image?.cgImage?.cropping(to: cropArea)
        let croppedImage = UIImage(cgImage: croppedCGImage!)
        selectedImageView.image = croppedImage
        scrollView.zoomScale = 1
        delegate?.didClickOnCropImage(image: croppedImage)
            removeFromSuperview()
        
    }
    
    @IBAction func didClickOnAspectRatio(_ sender: UIButton)
    {
        let alertViewController = UIAlertController(title: "", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let oneCrossOne = UIAlertAction(title: "1 X 1", style: UIAlertActionStyle.default, handler: {[weak self] (alertAction) -> Void in
            self?.changeAspectRatio(ratio: 1/1)
        })
        alertViewController.addAction(oneCrossOne)
        
        let threeCrossFour = UIAlertAction(title: "3 X 4", style: UIAlertActionStyle.default, handler: {[weak self] (alertAction) -> Void in
            self?.changeAspectRatio(ratio: 3/4)
        })
        alertViewController.addAction(threeCrossFour)
        
        let fourCrossThree = UIAlertAction(title: "4 X 3", style: UIAlertActionStyle.default, handler: {[weak self] (alertAction) -> Void in
            self?.changeAspectRatio(ratio: 4/3)
        })
        alertViewController.addAction(fourCrossThree)
        
        let sixteenCrossNine = UIAlertAction(title: "16 X 9", style: UIAlertActionStyle.default, handler: {[weak self] (alertAction) -> Void in
            self?.changeAspectRatio(ratio: 16/9)
        })
        alertViewController.addAction(sixteenCrossNine)
        
        let cancelAction = UIAlertAction(title:  "Cancel", style: UIAlertActionStyle.cancel, handler: { (alertAction) -> Void in
            
        })
        alertViewController.addAction(cancelAction)
        
        self.window?.rootViewController?.present(alertViewController, animated: true, completion: nil)
    }
    
    @IBAction func didClickOnCancelButton(_ sender: UIButton)
    {
        self.removeFromSuperview()
    }
    
    @IBAction func handlePanOnCropperView(_ sender: UIPanGestureRecognizer)
    {
        let translation = sender.translation(in:self)
        cropAreaView.center = CGPoint(x: sender.view!.center.x + translation.x, y: sender.view!.center.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: self)
    }
    
    @IBAction func handlePinchOnCropperView(_ sender: UIPinchGestureRecognizer)
    {
        var lastScale:CGFloat? = 1.0
        
        if sender.state == .began
        {
            lastScale = 1.0
        }
        
        let scale = 1.0 - (lastScale! - sender.scale)
        
        let newTransform = CGAffineTransform.init(scaleX: scale, y: scale)
        
        cropAreaView.transform = newTransform
        
        lastScale = sender.scale
    }
    
}

//MARK: Extensions
extension ImageCropperView:UIScrollViewDelegate
{
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return selectedImageView
    }
}

extension UIImageView
{
    //To calculate image frame (because content mode is aspect fit)
    func imageFrame()->CGRect{
        let imageViewSize = self.frame.size
        guard let imageSize = self.image?.size
            else{
                return CGRect.zero
        }
        let imageRatio = imageSize.width / imageSize.height
        let imageViewRatio = imageViewSize.width / imageViewSize.height
        if imageRatio < imageViewRatio
        {
            let scaleFactor = imageViewSize.height / imageSize.height
            let width = imageSize.width * scaleFactor
            let topLeftX = (imageViewSize.width - width) * 0.5
            return CGRect(x: topLeftX, y: 0, width: width, height: imageViewSize.height)
        }
        else
        {
            let scalFactor = imageViewSize.width / imageSize.width
            let height = imageSize.height * scalFactor
            let topLeftY = (imageViewSize.height - height) * 0.5
            return CGRect(x: 0, y: topLeftY, width: imageViewSize.width, height: height)
        }
    }
}

extension UIView {
    /** Loads instance from nib with the same name. */
    func loadNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nibName = type(of: self).description().components(separatedBy: ".").last!
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as! UIView
    }
}

extension NSLayoutConstraint {
    func constraintWithMultiplier(_ multiplier: CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: self.firstItem as Any, attribute: self.firstAttribute, relatedBy: self.relation, toItem: self.secondItem, attribute: self.secondAttribute, multiplier: multiplier, constant: self.constant)
    }
}

class CropperView: UIView {
    
    override func point(inside point: CGPoint, with event:   UIEvent?) -> Bool
    {
        return false
    }
}
