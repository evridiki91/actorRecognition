//
//  ViewController.swift
//  faceRecognition
//
//  Created by Evridiki Christodoulou on 21/01/2018.
//  Copyright © 2018 Evridiki Christodoulou. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var effect:UIVisualEffect!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet var infoView: UIView!
    @IBOutlet weak var BlurredView: UIVisualEffectView!
    @IBOutlet weak var classifier: UILabel!
    @IBOutlet weak var info: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        effect = BlurredView.effect
        BlurredView.effect = nil
        self.info.isHidden = true
    }
    
    var model: model_ft!
    override func viewWillAppear(_ animated: Bool) {
        model = model_ft()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    let imagePicker = UIImagePickerController()
   
    func animationOn() {
        self.info.isHidden = true
        self.classifier.isHidden = true
        self.view.addSubview(infoView)
        infoView.center = self.view.center
        infoView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        infoView.alpha = 0
        UIView.animate(withDuration: 0.4){
//            self.BlurredView.effect = self.effect
            self.infoView.alpha = 1
            self.infoView.transform = CGAffineTransform.identity
        }
    }
    
    func animationOff () {
        UIView.animate(withDuration: 0.3, animations:{
            self.infoView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
//            self.BlurredView.effect = nil
        }) {(success:Bool) in
                self.infoView.removeFromSuperview()
                self.info.isHidden = false
                self.classifier.isHidden = false
        }
    }
    
    @IBAction func moreInfo(_ sender: Any) {
        animationOn()
    }
    
    @IBAction func hideInfo(_ sender: Any) {
        animationOff()
    }
    
    
    @IBAction func cameraView(_ sender: UIButton) {
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func libraryView(_ sender: UIButton) {
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true)
        
        guard let newImage = info["UIImagePickerControllerOriginalImage"] as? UIImage else {
            return
        }
//        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
//        UIGraphicsEndImageContext()
        
        guard let visionModel = try? VNCoreMLModel(for: model.model) else {
            fatalError("Error")
        }
        
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let observations = request.results as? [VNClassificationObservation] {

                // The observations appear to be sorted by confidence already, so we
                // take the top 5 and map them to an array of (String, Double) tuples.
                let top5 = observations.prefix(through: 4)
                    .map { ($0.identifier, Double($0.confidence)) }
                self.show(results: top5)
                self.info.isHidden = false
            }
        }

        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(cgImage: newImage.cgImage!)
        try? handler.perform([request])
 
        imageView.image = newImage

        
//        classifier.text = "I think this is \(prediction.classLabel)."
//        print("This is \(prediction.classLabel) \n")
//        print("and \(prediction.prob) \n")
        
    }
    
    
    
    typealias Prediction = (String, Double)
    
    func show(results: [Prediction]) {
        var s: [String] = []
        for (i, pred) in results.enumerated() {
            s.append(String(format: "%d: %@ (%3.2f%%)", i + 1, pred.0, pred.1 * 100))
        }
        classifier.text = s.joined(separator: "\n\n")
        
    }
    
    func top(_ k: Int, _ prob: [String: Double]) -> [Prediction] {
        precondition(k <= prob.count)
        
        return Array(prob.map { x in (x.key, x.value) }
            .sorted(by: { a, b -> Bool in a.1 > b.1 })
            .prefix(through: k - 1))
    }
    
}

