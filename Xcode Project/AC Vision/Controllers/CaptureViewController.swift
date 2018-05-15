//
//  CaptureViewController.swift
//  BiciMad Incidencias
//
//  Created by Adolfo Vera Blasco on 28/4/18.
//  Copyright © 2018 desappstre {eStudio}. All rights reserved.
//

import UIKit
import Vision
import ImageIO
import AVFoundation

import IncidenceKit

internal class CaptureViewController: UIViewController, UINavigationControllerDelegate
{
    ///
    @IBOutlet private weak var imageBike: UIImageView!
    ///
    @IBOutlet private weak var labelIdentifier: UILabel!
    ///
    @IBOutlet private weak var buttonLoadImage: UIButton!
    
    ///
    private var requestText: VNDetectTextRectanglesRequest!
    
    private var queue: DispatchQueue!
    
    ///
    private var ciBikeImage: CIImage?

    private let redColorMarker = UIColor(hexadecimal: "#cc0055")
    private let blueColorMarker = UIColor(hexadecimal: "#0055cc")
    
    ///
    private lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.sourceType = .savedPhotosAlbum
        picker.modalPresentationStyle = .currentContext
        picker.delegate = self as? (UIImagePickerControllerDelegate & UINavigationControllerDelegate)
        
        return picker
    }()

    

    //
    // MARK: - Life Cycle
    //

    /**
        Aplicamos el tema visual
    */
    override internal func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.applyTheme()
        
        self.labelIdentifier.text = ""
        
        self.queue = DispatchQueue(label: "com.applecoding.Vision./ml_process", attributes: .concurrent)
    }
    
    /**
        Preparamos la detección de texto
    */
    override internal func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.prepareTextDetection()
    }
    
    //
    // MARK: - Prepare UI
    //
    
    /**
        Colors y demás...
    */
    private func applyTheme() -> Void
    {
        self.imageBike.layer.cornerRadius = 8.0
        self.imageBike.layer.masksToBounds = true
        
        self.labelIdentifier.textColor = UIColor(hexadecimal: "#424242")
    }
    
    //
    // MARK: - Vision
    //
    
    /**
        Inicializamos la *request* de detección de texto
    */
    private func prepareTextDetection() -> Void
    {
        self.requestText = VNDetectTextRectanglesRequest(completionHandler: self.handleTextDetection)
        self.requestText.reportCharacterBoxes = true
    }
    
    /**
        Gestionamos cada una de las detecciones de texto
        informadas por `Vision`
    */
    private func handleTextDetection(request: VNRequest, error: Error?) -> Void
    {
        // Quitamos los marcadores de detección que 
        // aparecen sobre la imagen
        DispatchQueue.main.async
        {
            self.imageBike.subviews.forEach({ $0.removeFromSuperview() })
        }

        guard let results = request.results, let ciBikeImage = self.ciBikeImage, !results.isEmpty else
        {
            return
        }
        
        guard let result = results.first,
              let observation = result as? VNTextObservation,
              observation.isBikeIdentifier
        else
        {
            return
        }
        
        DispatchQueue.main.async
        {
            self.showMarker(relativeTo: observation.boundingBox, withColor: self.redColorMarker)
        }
        
        let visionary = Visionary()
        visionary.delegate = self
        
        let imageSize = ciBikeImage.extent.size
        var boxes = [CIImage]()
        
        for box in observation.characterBoxes!
        {
            DispatchQueue.main.async
            {
                self.showMarker(relativeTo: box.boundingBox, withColor: self.blueColorMarker)
            }
            
            let box_rect = box.boundingBox.scaled(to: imageSize)
            
            // Rectify the detected image and reduce it to inverted grayscale for applying model.
            let topLeft = box.topLeft.scaled(to: imageSize)
            let topRight = box.topRight.scaled(to: imageSize)
            let bottomLeft = box.bottomLeft.scaled(to: imageSize)
            let bottomRight = box.bottomRight.scaled(to: imageSize)
            
            let correctedImage = ciBikeImage
                .cropped(to: box_rect)
                .applyingFilter("CIColorInvert")
                .applyingFilter("CIPerspectiveCorrection", parameters: [
                    "inputTopLeft": CIVector(cgPoint: topLeft),
                    "inputTopRight": CIVector(cgPoint: topRight),
                    "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                    "inputBottomRight": CIVector(cgPoint: bottomRight)
                    ])
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputSaturationKey: 0,
                    kCIInputContrastKey: 32
                    ])
            
            boxes.append(correctedImage)
        }
        
        visionary.prediction(images: boxes)
    }
    
    /**
 
    */
    private func showMarker(relativeTo boundingBox: CGRect, withColor color: UIColor) -> Void
    {
        let rect = boundingBox.scaled(to: self.imageBike.bounds.size)
        
         let mark = UIView(frame: rect)
         mark.layer.borderColor = color.cgColor
         mark.layer.borderWidth = 2.0
        
         self.imageBike.addSubview(mark)
    }
    
    //
    // MARK: - Actions
    //
    
    /**
 
    */
    @IBAction private func handleLoadImageButtonTap(sender: UIButton) -> Void
    {
        self.labelIdentifier.text = "· · · ·"
        
        self.present(self.imagePicker, animated: true, completion: nil)
        
        sender.tapFeedback()
    }
}

//
// MARK: - UIImagePickerControllerDelegate Protocol
//

extension CaptureViewController: UIImagePickerControllerDelegate
{
    /**
 
    */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) -> Void
    {
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage,
              let image_url = info[UIImagePickerControllerImageURL] as? URL,
              let ciImage = CIImage(contentsOf: image_url)
        else
        {
            return
        }

        self.imageBike.image = image
        self.ciBikeImage = ciImage
        
        DispatchQueue.global(qos: .userInitiated).async 
        {
        let imageRequest = VNImageRequestHandler(ciImage: ciImage)

        do 
        {
            try imageRequest.perform([ self.requestText ])    
        } 
        catch let error
        {
            print("No podemos procesar la imagen del Carrete de Fotos. \(error.localizedDescription)")
        }
        }
    }

    /**
 
    */
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) -> Void
    {
        picker.dismiss(animated: true, completion: nil)
    }
}

//
// MARK: - VisionaryDelegate Protocol
//

extension CaptureViewController: VisionaryDelegate
{
    /**
        El número que aparece en la imagen
    */
    func visionary(_ visionary: Visionary, didCaptureIdentifierNumber identifier: Int) -> Void
    {
        DispatchQueue.main.async
        {
            self.labelIdentifier.text = "\(identifier)"
        }
    }
}

