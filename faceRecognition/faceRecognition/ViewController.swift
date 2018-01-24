//
//  ViewController.swift
//  faceRecognition
//
//  Created by Evridiki Christodoulou on 21/01/2018.
//  Copyright © 2018 Evridiki Christodoulou. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var pictureImageView: UIImageView!
    
    
    @IBAction func cameraView(_ sender: UIButton) {
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func libraryView(_ sender: UIButton) {
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject]){
            let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            pictureImageView.image = chosenImage
            dismiss(animated:true, completion: nil)
            //classify(image: image) //This will be a function that will use the VGG2 model
        }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

