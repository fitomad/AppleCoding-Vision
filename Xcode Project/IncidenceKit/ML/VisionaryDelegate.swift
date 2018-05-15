//
//  VisionaryDelegate.swift
//  IncidenceKit
//
//  Created by Adolfo Vera Blasco on 2/5/18.
//  Copyright © 2018 desappstre {eStudio}. All rights reserved.
//

import Foundation

public protocol VisionaryDelegate: AnyObject
{
    /**
        Devuelve el número que aparece en la imagen

        - Parameters:
            - visionary: El objeto encargado del procesamiento de la imagen
            - identifier: El número que hay en la imagen
    */
    func visionary(_ visionary: Visionary, didCaptureIdentifierNumber identifier: Int) -> Void
}
