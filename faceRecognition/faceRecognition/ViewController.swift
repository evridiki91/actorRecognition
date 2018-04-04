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


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UITableViewDataSource,UITableViewDelegate {
  
    
    
    //var effect:UIVisualEffect!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet var infoView: UIView!
    //@IBOutlet weak var BlurredView: UIVisualEffectView!
    @IBOutlet weak var classifier: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    //@IBOutlet weak var percentage: UILabel!
    @IBOutlet weak var info: UIButton!
    @IBOutlet weak var informationLabel: UILabel!
    var finalImage: UIImage!
    var finalImages: [UIImage] = []
    var flag: Bool!
    var nameList: [String] = []
    var informationList: [String] = []
    var imageLibrary: UIImage!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = true
        tableView.layer.cornerRadius = tableView.frame.height/22
        self.info.isHidden = true
        imageView.isHidden = true
        self.classifier.isHidden = true
        self.classifier.text = ""
        imageView.layer.borderWidth = 0
        imageView.layer.masksToBounds = false
        imageView.layer.cornerRadius = min(imageView.frame.size.height, imageView.frame.size.width) / 2.0
        imageView.clipsToBounds = true
        
        infoView.layer.masksToBounds = false
        infoView.layer.cornerRadius = informationLabel.frame.height/8
        infoView.clipsToBounds = true
        imageView.image = finalImage
        
        if (flag == true){
            self.callPrediction()
        }
        
        
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return finalImages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = tableView.dequeueReusableCell( withIdentifier: "customCell", for: indexPath) as! CustomViewCell
        cell.cellView.layer.cornerRadius = cell.cellView.frame.height/8
        cell.cellImage.image = finalImages[indexPath.row]
        cell.cellLabel.text = nameList[indexPath.row]
        cell.cellImage.layer.cornerRadius = cell.cellImage.frame.height/4
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.informationLabel.text = informationList[indexPath.row]
        animationOn()
        
    }
    
    
    
    
    @IBAction func learnMoreButton(_ sender: Any) {
        self.infoView.isHidden = false
        self.informationLabel.text = "HEY"
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
                 self.informationList.append(persons.itemListElement.first!.result.detailedDescription.articleBody)
                
                
            
                print(self.informationList)
              //  self.informationLabel.text = persons.itemListElement.first!.result.detailedDescription.articleBody
            }
            //print("All stuff are: \(persons.itemListElement.first!.result.detailedDescription.articleBody)")
            
        } catch let err {
        self.informationList.append("No information available for this person")
        print("Error", err)
        }
        }.resume()
    }
    
    let model = model_ft()
//    var model: model_ft!
//    override func viewWillAppear(_ animated: Bool) {
//        model = model_ft()
//    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    let imagePicker = UIImagePickerController()
    
    func animationOn() {
        self.info.isHidden = true
        self.classifier.isHidden = true
        //self.percentage.isHidden = true
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
                //self.info.isHidden = false
                //self.classifier.isHidden = false
               // self.percentage.isHidden = false
        }
    }
    
    @IBAction func moreInfo(_ sender: Any) {
        animationOn()
    }
    
    @IBAction func hideInfo(_ sender: Any) {
        animationOff()
    }
    
    
//    @IBAction func cameraView(_ sender: UIButton) {
//        imagePicker.sourceType = .camera
//        imagePicker.allowsEditing = false
//        present(imagePicker, animated: true, completion: nil)
//    }
    @IBAction func goToCameraView(_ sender: Any) {
        performSegue(withIdentifier: "segueToCamera", sender: self)
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
        //let startTime = CFAbsoluteTimeGetCurrent()
        for _ in 1...1 {
            //self.imageView.image = newImage
           // self.imageView.isHidden = false
           // self.classifier.isHidden = false
           // self.info.isHidden = false
//            self.imageLibrary = newImage
            self.predictUsingVision(image: newImage)

        }
    }
    
    
    
    
    /*
     This uses the Vision framework to drive Core ML.
     Note that this actually gives a slightly different prediction. This must
     be related to how the UIImage gets converted.
     */
    func predictUsingVision(image: UIImage) {
        guard let visionModel = try? VNCoreMLModel(for: model.model) else {
            fatalError("Error")
        }
        
        
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let observations = request.results as? [VNClassificationObservation] {
                
                // The observations appear to be sorted by confidence already, so we
                // take the top 5 and map them to an array of (String, Double) tuples.
                //print(observations)
                self.show(result: (observations[0].identifier,Double(observations[0].confidence)))
                //self.info.isHidden = false
            }
        }
        
        request.imageCropAndScaleOption = .centerCrop
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!)
        try? handler.perform([request])
        tableView.isHidden = false
        //imageView.isHidden = false
        //imageView.image = image
    }
    
    typealias Prediction = (String, Double)
    
    func show(result: Prediction) {
        let string = result.0 + String(format: " %.2f", result.1*100) + "%"
        let nameString = result.0
        //self.classifier.text = string
        print("String \(string)")
        //print(classifier.text)
        //let parsed_string = string.replacingOccurrences(of: "\\s?\\([^)]*\\)", with: "", options: .regularExpression)
       
        let name = (nameString).replacingOccurrences(of: " ", with: "+")
        loadFromApi(name: name)
        
        self.nameList.append(string)
        print(nameList)
        //self.classifier.isHidden = false
        
        

    }
    
    func callPrediction(){
        for image in finalImages {
        predictUsingVision(image: image)
        }
    }
    
    
}


