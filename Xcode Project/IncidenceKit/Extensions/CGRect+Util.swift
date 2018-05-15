//
//  CGRect+Util.swift
//  IncidenceKit
//
//  Created by Adolfo Vera Blasco on 1/5/18.
//  Copyright © 2018 desappstre {eStudio}. All rights reserved.
//

import Foundation

public extension CGRect
{
    public func scaled(to size: CGSize) -> CGRect
    {
        return CGRect(
            x: self.origin.x * size.width,
            y: self.origin.y * size.height,
            width: self.size.width * size.width,
            height: self.size.height * size.height
        )
    }
}
