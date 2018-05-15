//
//  CGPoint+Util.swift
//  IncidenceKit
//
//  Created by Adolfo Vera Blasco on 1/5/18.
//  Copyright © 2018 desappstre {eStudio}. All rights reserved.
//

import Foundation

public extension CGPoint
{
    public func scaled(to size: CGSize) -> CGPoint
    {
        return CGPoint(x: self.x * size.width, y: self.y * size.height)
    }
}
