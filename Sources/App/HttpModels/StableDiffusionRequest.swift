//
//  File.swift
//  
//
//  Created by Alexander Ng on 27/1/24.
//

import Foundation
import Vapor

struct StableDiffusionRequest: Content {
    let prompt: String
    let seed: String
    let numImages: String
}
