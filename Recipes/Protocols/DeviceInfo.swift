//
//  DeviceInfo.swift
//  Recipes
//
//  Created by Craig Boyce on 3/17/25.
//

import UIKit

protocol DeviceInfo {
    var isIpad: Bool { get }
}

class DefaultDeviceInfo: DeviceInfo {
    var isIpad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}
