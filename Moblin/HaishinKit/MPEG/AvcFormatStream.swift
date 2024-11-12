import Foundation

let nalUnitStartCode = Data([0x00, 0x00, 0x00, 0x01])

// Should escape as well?
func addNalUnitStartCodes(_ data: inout Data) {
    var index = 0
    while index < data.count {
        let length = data.getFourBytesBe(offset: index)
        data.replaceSubrange(index ..< index + 4, with: nalUnitStartCode)
        index += Int(length) + 4
    }
}

// Should unescape as well? Why can length be 3 or 4 bytes? Correct?
func removeNalUnitStartCodes(_ data: inout Data) {
    var lastIndexOf = data.count - 1
    for index in (2 ..< data.count).reversed() {
        guard data[index] == 1, data[index - 1] == 0, data[index - 2] == 0 else {
            continue
        }
        let startCodeLength = index - 3 >= 0 && data[index - 3] == 0 ? 4 : 3
        let start = 4 - startCodeLength
        let length = lastIndexOf - index
        guard length > 0 else {
            continue
        }
        data.replaceSubrange(
            index - startCodeLength + 1 ... index,
            with: Int32(length).bigEndian.data[start...]
        )
        lastIndexOf = index - startCodeLength
    }
}
