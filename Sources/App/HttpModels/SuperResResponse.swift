

import Foundation
import Vapor

struct SuperResResponse : Content, ResponseEncodable{
    var image: String
    init(image: String) {
            self.image = image
        }
}
