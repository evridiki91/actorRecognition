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

struct Json: Decodable {
    let itemListElement: [ItemListElements]
}

struct ItemListElements: Decodable {
    let result: Result

}

struct Result: Decodable {
    let detailedDescription: Description
}

struct Description: Decodable {
    let articleBody: String
    let license: String
}


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var effect:UIVisualEffect!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet var infoView: UIView!
    @IBOutlet weak var BlurredView: UIVisualEffectView!
    @IBOutlet weak var classifier: UILabel!
    @IBOutlet weak var percentage: UILabel!
    @IBOutlet weak var info: UIButton!
    @IBOutlet weak var informationLabel: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        effect = BlurredView.effect
        BlurredView.effect = nil
        self.info.isHidden = true
        imageView.isHidden = true
        classifier.isHidden = true
        imageView.layer.borderWidth = 0
        imageView.layer.masksToBounds = false
        imageView.layer.cornerRadius = min(imageView.frame.size.height, imageView.frame.size.width) / 2.0
        imageView.clipsToBounds = true
        
        infoView.layer.masksToBounds = false
        infoView.layer.cornerRadius = informationLabel.frame.height/2.8
        infoView.clipsToBounds = true
    }
    
    
    func loadFromApi(name:String){
        guard let apiUrl = URL(string: "https://kgsearch.googleapis.com/v1/entities:search?indent=true&limit=1&query=\(name)&types=Person&key=AIzaSyDGzQoD9N3a517IZP1vlzktUH1ASUnHOyo")
            else {
                print("error parsing URL")
                return
        }
        
        URLSession.shared.dataTask(with: apiUrl) { (data, response
        , error) in
        guard let data = data else { return }
        do {
//            let json = try JSONSerialization.jsonObject(with: data, options: [])
//            print(json)
        let decoder = JSONDecoder()
        let persons = try decoder.decode(Json.self, from: data)
            DispatchQueue.main.async {
            self.informationLabel.text = persons.itemListElement.first!.result.detailedDescription.articleBody
            }
            //print("All stuff are: \(persons.itemListElement.first!.result.detailedDescription.articleBody)")
            
        } catch let err {
        print("Err", err)
        }
        }.resume()
    }
    
    var model: VGG16Face!
    override func viewWillAppear(_ animated: Bool) {
        model = VGG16Face()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    let imagePicker = UIImagePickerController()
    
    
    func animationOn() {
        self.info.isHidden = true
        self.classifier.isHidden = true
        self.percentage.isHidden = true
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
            self.infoView.transform = CGAffineTransform.init(scaleX: 1.2, y: 1.2)
//            self.BlurredView.effect = nil
        }) {(success:Bool) in
                self.infoView.removeFromSuperview()
                self.info.isHidden = false
                self.classifier.isHidden = false
                self.percentage.isHidden = false
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
        let startTime = CFAbsoluteTimeGetCurrent()
        for _ in 1...50 {
            guard let visionModel = try? VNCoreMLModel(for: model.model) else {
                fatalError("Error")
            }
            
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if let observations = request.results as? [VNClassificationObservation] {

                    // The observations appear to be sorted by confidence already, so we
                    // take the top 5 and map them to an array of (String, Double) tuples.
                    let top = observations.prefix(through: 0)
                        .map { ($0.identifier, Double($0.confidence)) }
                    self.show(results: top)
                    self.info.isHidden = false
                }
            }

            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: newImage.cgImage!)
            try? handler.perform([request])
            
            imageView.isHidden = false
            imageView.image = newImage

            
    //        classifier.text = "I think this is \(prediction.classLabel)."
    //        print("This is \(prediction.classLabel) \n")
    //        print("and \(prediction.prob) \n")
        }
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("Time elapsed for \(timeElapsed) s.")

    }
    
    
    
    typealias Prediction = (String, Double)
    
    func show(results: [Prediction]) {
        var s: [String] = []
        for (_,pred) in results.enumerated() {
            s.append(String(format: " %@ (%3.2f%%)", pred.0, pred.1 * 100))
            //print separately the name and percentage
        }
        
        let string = s.joined(separator: "\n")
        classifier.text = string
        classifier.isHidden = false
        let parsed_string = string.replacingOccurrences(of: "\\s?\\([^)]*\\)", with: "", options: .regularExpression)
        
        //print("classifier text: \(classifier.text)")
        let name = (parsed_string).replacingOccurrences(of: " ", with: "+")
        loadFromApi(name: name)
        //print("new text: \(text)")
        //print("Predictions: \(s)")

    }

    
}

