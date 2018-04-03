//
//  ViewControllerYOLO.swift
//  faceRecognition
//
//  Created by Evridiki Christodoulou on 31/03/2018.
//  Copyright © 2018 Evridiki Christodoulou. All rights reserved.
//
import UIKit
import Vision
import AVFoundation
import CoreMedia
import VideoToolbox
import CoreML

class ViewControllerYOLO: UIViewController {
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var captureButton: UIButton!
    
    let yolo = YOLO()
    
    var videoCapture: VideoCapture!
    var request: VNCoreMLRequest!
    var startTimes: [CFTimeInterval] = []
    var imageToDetect: CVPixelBuffer?
    var boundingBoxes = [BoundingBox]()
    var colors: [UIColor] = []
    
    var framesDone = 0
    var frameCapturingStartTime = CACurrentMediaTime()
    let semaphore = DispatchSemaphore(value: 2)
    var faces: [CGRect] = []

    var imageToPass: UIImage!
    var imagesToPass: [UIImage] = []
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //    timeLabel.text = ""
        
        setUpBoundingBoxes()
        setUpVision()
        setUpCamera()
        
        frameCapturingStartTime = CACurrentMediaTime()
        
        //    // Get an instance of ACCapturePhotoOutput class
        //    capturePhotoOutput = AVCapturePhotoOutput()
        //    capturePhotoOutput?.isHighResolutionCaptureEnabled = true
        //    // Set the output on the capture session
        //    videoCapture.captureSession.addOutput(capturePhotoOutput!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print(#function)
    }
    
    // MARK: - Initialization
    
    func setUpBoundingBoxes() {
        for _ in 0..<YOLO.maxBoundingBoxes {
            boundingBoxes.append(BoundingBox())
        }
        
        // Make colors for the bounding boxes. There is one color for each class,
        // 80 classes in total.
        for r: CGFloat in [0.2, 0.4, 0.6, 0.85, 1.0] {
            for g: CGFloat in [0.6, 0.7, 0.8, 0.9] {
                for b: CGFloat in [0.6, 0.7, 0.8, 1.0] {
                    let color = UIColor(red: r, green: g, blue: b, alpha: 1)
                    colors.append(color)
                }
            }
        }
    }
   
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "backToMain"){
            let destination = segue.destination as! ViewController
            print("Back to Main")
            //destination.finalImage = self.imageToPass
            destination.finalImages = self.imagesToPass
            destination.flag = true
        }
    }
    
    
    //Button for capturing image
    @IBAction func captureImage(_ sender: Any) {
        print("captured")
        
        if let image = UIImage(pixelBuffer: self.imageToDetect!) {
            
            // Add the view to the view hierarchy so that it shows up on screen
            for face in self.faces{
                
                let croppedCGImage:CGImage = (image.cgImage?.cropping(to: face))!
                let croppedImage = UIImage(cgImage: croppedCGImage,scale: image.scale, orientation: image.imageOrientation)
                self.imagesToPass.append(croppedImage)
                //self.imageToPass = croppedImage
                
               
                
//                UIImageWriteToSavedPhotosAlbum(croppedImage, nil, nil, nil);
//                print("saved")
//                print(faces.count)
                
            }
            performSegue(withIdentifier: "backToMain", sender: self)
        }
        
    }
    
  
    
//    @IBAction func goBackToMainView(_ sender: Any) {
//        if sender.source is ViewControllerYOLO
//        performSegue(withIdentifier: "backToMain", sender: self)
//    }
    
    func setUpVision() {
        guard let visionModel = try? VNCoreMLModel(for: yolo.model.model) else {
            print("Error: could not create Vision model")
            return
        }
        
        request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
        
        // NOTE: If you choose another crop/scale option, then you must also
        // change how the BoundingBox objects get scaled when they are drawn.
        // Currently they assume the full input image is used.
        request.imageCropAndScaleOption = .scaleFill
    }
    
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 5
        videoCapture.setUp(sessionPreset: AVCaptureSession.Preset.vga640x480) { success in
            if success {
                // Add the video preview into the UI.
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                
                // Add the bounding box layers to the UI, on top of the video preview.
                for box in self.boundingBoxes {
                    box.addToLayer(self.videoPreview.layer)
                }
                
                // Once everything is set up, we can start capturing live video.
                self.videoCapture.start()
            }
        }
    }
    
    @IBAction func stopCamera(_ sender: Any) {
        if self.videoCapture.captureSession.isRunning {
            self.videoCapture.stop()
        }
        else{
            self.videoCapture.start()
        }
    }
    
    
    // MARK: - UI stuff
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        resizePreviewLayer()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }
    
    // MARK: - Doing inference
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        // Measure how long it takes to predict a single video frame. Note that
        // predict() can be called on the next frame while the previous one is
        // still being processed. Hence the need to queue up the start times.
        startTimes.append(CACurrentMediaTime())
        
        // Vision will automatically resize the input image.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }
    
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
            let features = observations.first?.featureValue.multiArrayValue {
            
            let boundingBoxes = yolo.computeBoundingBoxes(features: features)
            let elapsed = CACurrentMediaTime() - startTimes.remove(at: 0)
            showOnMainThread(boundingBoxes, elapsed)
        }
    }
    
    func showOnMainThread(_ boundingBoxes: [YOLO.Prediction], _ elapsed: CFTimeInterval) {
        DispatchQueue.main.async {
            
            self.show(predictions: boundingBoxes)
            
            let fps = self.measureFPS()
            self.timeLabel.text = String(format: "Elapsed %.5f seconds - %.2f FPS", elapsed, fps)
            self.semaphore.signal()
        }
    }
    
    func measureFPS() -> Double {
        // Measure how many frames were actually delivered per second.
        framesDone += 1
        let frameCapturingElapsed = CACurrentMediaTime() - frameCapturingStartTime
        let currentFPSDelivered = Double(framesDone) / frameCapturingElapsed
        if frameCapturingElapsed > 1 {
            framesDone = 0
            frameCapturingStartTime = CACurrentMediaTime()
        }
        return currentFPSDelivered
    }
    
    func show(predictions: [YOLO.Prediction]) {
        self.faces = [] //Initialise list of faces to be empty
        for i in 0..<boundingBoxes.count {
            if i < predictions.count {
                let prediction = predictions[i]
                
                let width =  CGFloat(480)
                let height = CGFloat(640)
                let scaleX = width / CGFloat(YOLO.inputWidth)
                let scaleY = height / CGFloat(YOLO.inputHeight)
                let top = (height - height) / 2
                
                var rectImage = prediction.rect
                
                rectImage.origin.x *= scaleX
                rectImage.origin.y *= scaleY
                rectImage.origin.y += top
                rectImage.size.width *= scaleX
                rectImage.size.height *= scaleY
                
                
                if(!self.videoCapture.captureSession.isRunning){
                    self.faces.append(rectImage)
                    print("faces")
                    print(faces) //testing
                    
                }
                
                
                
                // The predicted bounding box is in the coordinate space of the input
                // image, which is a square image of 416x416 pixels. We want to show it
                // on the video preview, which is as wide as the screen and has a 4:3
                // aspect ratio. The video preview also may be letterboxed at the top
                // and bottom.
                let widthView =  view.bounds.width
                let heightView = widthView * 4 / 3
                let scaleXView = widthView / CGFloat(YOLO.inputWidth)
                let scaleYView = heightView / CGFloat(YOLO.inputHeight)
                let topView = (view.bounds.height - heightView) / 2
                
                // Translate and scale the rectangle to our own coordinate system.
                var rect = prediction.rect
                
                rect.origin.x *= scaleXView
                rect.origin.y *= scaleYView
                rect.origin.y += topView
                rect.size.width *= scaleXView
                rect.size.height *= scaleYView
                // Show the bounding box.
                let label = String(format: "%@ %.1f", labels[prediction.classIndex], prediction.score * 100)
                let color = colors[prediction.classIndex]
                boundingBoxes[i].show(frame: rect, label: label, color: color)
                
            } else {
                boundingBoxes[i].hide()
            }
            
            
            
            
        }
    }
}

extension ViewControllerYOLO: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        // For debugging.
        //predict(image: UIImage(named: "dog416")!); return
        
        semaphore.wait()
        
        if let pixelBuffer = pixelBuffer {
            // For better throughput, perform the prediction on a background queue
            // instead of on the VideoCapture queue. We use the semaphore to block
            // the capture queue and drop frames when Core ML can't keep up.
            DispatchQueue.global().async {
                //self.predict(pixelBuffer: pixelBuffer)
                self.imageToDetect = pixelBuffer
                self.predictUsingVision(pixelBuffer: pixelBuffer)
            }
        }
    }
}

