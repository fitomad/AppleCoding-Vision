//
//  Visionary.swift
//  IncidenceKit
//
//  Created by Adolfo Vera Blasco on 2/5/18.
//  Copyright © 2018 desappstre {eStudio}. All rights reserved.
//

import Vision
import CoreML
import Foundation

public class Visionary
{
    // Modelo que nos dirá qué número se corresponda
    // con la imagene que le presentamos
    private let model: VNCoreMLModel?
    /// El número de serie de la imagen
    private var serial: (thousands: Int?, hundreds: Int?, tens: Int?, units: Int?)
    /// Delegado donde informar de los resultados
    public weak var delegate: VisionaryDelegate?

    /**
        Preparamos el modelo
    */
    public init()
    {
        self.model = try? VNCoreMLModel(for: MLBiciMAD().model)
        self.serial = (thousands: nil, hundreds: nil, tens: nil, units: nil)
    }
    
    /**
     
        - Parameter images: Cada uno de las imagenes que se supone 
            corresponden a un dígito
    */
    public func prediction(images: [CIImage]) -> Void
    {
        guard let model = self.model else
        {
            return
        }
        
        for (index, image) in images.enumerated()
        {
            let request = VNCoreMLRequest(model: model) { [weak self] (request, error) -> Void in
                self?.handleModelRequest(request: request, forIndex: index)
            }

            // Como escalamos la imagen para adecuarla al
            // tamaño esperado por el modelo.    
            request.imageCropAndScaleOption = .scaleFit

            let handler = VNImageRequestHandler(ciImage: image)
            
            do
            {
                try handler.perform([ request ])
            }
            catch let error
            {
                print("No se puede ejecutar la operación con Vision. \(error.localizedDescription)")
            }
        }
    }
    
    //
    // MARK: - CoreML Model
    //
    
    /**
        La respuesta del modelo ante una imagen presentada

        - Parameters:
            - request: Información de respuesta
            - index: Posición de la imagen dentro de la *palabra*
    */
    private func handleModelRequest(request: VNRequest, forIndex index: Int) -> Void
    {
        guard let results = request.results as? [VNClassificationObservation],
              let observation = results.first,
              let digit = Int(observation.identifier)
        else
        {
            return
        }
        
        switch index
        {
            case 0:
                self.serial.thousands = digit
            case 1:
                self.serial.hundreds = digit
            case 2:
                self.serial.tens = digit
            default:
                self.serial.units = digit
        }
        
        if let thousands = serial.thousands,
           let hundreds = serial.hundreds,
           let tens = serial.tens,
           let units = serial.units,
           let serial_number = Int("\(thousands)\(hundreds)\(tens)\(units)")
        {
            self.delegate?.visionary(self, didCaptureIdentifierNumber: serial_number)
        }
    }
}
