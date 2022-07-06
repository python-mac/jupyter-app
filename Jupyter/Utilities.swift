import Foundation

extension String {
    
    func get(after startString: String? = nil, until endString: String? = nil) -> String {
        // get part of the Srting as a new object
        // start and end strings are not included
        
        let start, end: String.Index
        
        if let startString = startString {
            if let beginning = self.range(of: startString,
                                          range: self.startIndex..<self.endIndex) {
                start = beginning.upperBound
            } else {
                start = self.endIndex
            }
            
        } else {
            start = self.startIndex
        }
        
        if let endString = endString {
            if let ending = self.range(of: endString,
                                       range: start..<self.endIndex) {
                end = ending.lowerBound
            } else {
                end = self.endIndex
            }
            
        } else {
            end = self.endIndex
        }
        
        return String(self[start..<end])
    }
}
