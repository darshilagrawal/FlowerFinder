//
//  ViewController.swift
//  WhatFlower
//
//  Created by Darshil Agrawal on 06/10/20.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController,UINavigationControllerDelegate,UIImagePickerControllerDelegate {
    
    let imagePicker=UIImagePickerController()
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate=self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing=true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage=info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            guard let ciImage=CIImage(image: pickedImage) else {
                fatalError("Could not convert to CIImage")
            }
            detect(flowerImage: ciImage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cameraButtonClicked(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func requestInfo(flowerName:String) {
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                print("Got the wikipedia Info")
                print(response)
                let flowerJSON:JSON=JSON(response.result.value!)
                let pageID=flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageID]["extracts"].stringValue
                let flowerImageURL=flowerJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                self.label.text=flowerDescription
                self.label.textColor = .black
            }
        }
    }
    
    func detect(flowerImage:CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Could Not Load MLModel")
        }
        let request=VNCoreMLRequest(model: model) { (request, error) in
            guard let results=request.results as? [VNClassificationObservation] else {
                fatalError("Error fetching results")
            }
            if let firstResult=results.first?.identifier {
                self.navigationItem.title=firstResult.capitalized
                self.requestInfo(flowerName: firstResult)
            }
        }
        let handler=VNImageRequestHandler(ciImage:flowerImage)
        do{
            try handler.perform([request])
        }
        catch{
            print(error)
        }
    }
}

