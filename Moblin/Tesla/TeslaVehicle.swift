import CoreBluetooth
import CryptoKit
import CryptorECC
import Telegraph

private let vehicleServiceUuid = CBUUID(string: "00000211-b2d1-43f0-9b88-960cebf8b91e")
private let toVehicleUuid = CBUUID(string: "00000212-b2d1-43f0-9b88-960cebf8b91e")
private let fromVehicleUuid = CBUUID(string: "00000213-b2d1-43f0-9b88-960cebf8b91e")

enum TeslaVehicleState {
    case idle
    case discovering
    case connecting
    case handshaking
}

class TeslaVehicle: NSObject {
    private let vin: String
    private let privateKeyPem: String
    private let privateKey: ECPrivateKey
    private var centralManager: CBCentralManager?
    private var vehiclePeripheral: CBPeripheral?
    private var toVehicleCharacteristic: CBCharacteristic?
    private var fromVehicleCharacteristic: CBCharacteristic?
    private var state: TeslaVehicleState = .idle
    private var responseHandlers: [Data: (UniversalMessage_RoutableMessage) throws -> Void] = [:]
    private var receivedData = Data()
    private var sessionInfo: Signatures_SessionInfo?

    init?(vin: String, privateKey: String) {
        self.vin = vin
        privateKeyPem = privateKey
        do {
            self.privateKey = try ECPrivateKey(key: privateKey)
        } catch {
            logger.error("tesla-vehicle: Error \(error)")
            return nil
        }
    }

    func start() {
        setState(state: .discovering)
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func stop() {
        centralManager = nil
        vehiclePeripheral = nil
        toVehicleCharacteristic = nil
        fromVehicleCharacteristic = nil
    }

    func openTrunk() {
        var closureMoveRequest = VCSEC_ClosureMoveRequest()
        closureMoveRequest.rearTrunk = .closureMoveTypeOpen
        executeClosureMoveAction(closureMoveRequest)
    }

    func closeTrunk() {
        var closureMoveRequest = VCSEC_ClosureMoveRequest()
        closureMoveRequest.rearTrunk = .closureMoveTypeClose
        executeClosureMoveAction(closureMoveRequest)
    }

    func honk() {
        var action = CarServer_Action()
        action.vehicleAction.vehicleControlHonkHornAction = .init()
        executeCarServerAction(action)
    }

    func flashLights() {
        var action = CarServer_Action()
        action.vehicleAction.vehicleControlFlashLightsAction = .init()
        executeCarServerAction(action)
    }

    func getChargeState() {}

    private func executeClosureMoveAction(_ closureMoveRequest: VCSEC_ClosureMoveRequest) {
        var unsignedMessage = VCSEC_UnsignedMessage()
        unsignedMessage.closureMoveRequest = closureMoveRequest
        do {
            let payload = try unsignedMessage.serializedData()
            try sendPayloadRequest(domain: .vehicleSecurity, payload: payload)
        } catch {
            logger.info("tesla-vehicle: Execute closure move action error \(error)")
        }
    }

    private func executeCarServerAction(_ action: CarServer_Action) {
        do {
            let payload = try action.serializedData()
            try sendPayloadRequest(domain: .infotainment, payload: payload)
        } catch {
            logger.info("tesla-vehicle: Send payload request error \(error)")
        }
    }

    private func setState(state: TeslaVehicleState) {
        guard state != self.state else {
            return
        }
        logger.info("tesla-vehicle: State change \(self.state) -> \(state)")
        self.state = state
    }

    private func localName() -> String {
        let hash = SHA1.hash(vin.utf8Data).prefix(8).hexString()
        return "S\(hash)C"
    }

    private func getNextAddress() -> Data {
        return Data.random(length: 16)
    }

    private func startHandshake() throws {
        setState(state: .handshaking)
        // sendSessionInfoRequest(domain: .vehicleSecurity)
        try sendSessionInfoRequest(domain: .infotainment)
    }

    private func sendSessionInfoRequest(domain: UniversalMessage_Domain) throws {
        let address = getNextAddress()
        let uuid = Data.random(length: 16)
        var message = UniversalMessage_RoutableMessage()
        message.toDestination.domain = domain
        message.fromDestination.routingAddress = address
        message.sessionInfoRequest.publicKey = privateKey.pubKeyBytes
        message.uuid = uuid
        responseHandlers[address] = handleSessionInfoResponse(message:)
        try sendMessage(message: message)
    }

    private func handleSessionInfoResponse(message: UniversalMessage_RoutableMessage) throws {
        sessionInfo = try Signatures_SessionInfo(serializedBytes: message.sessionInfo)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.flashLights()
        }
    }

    private func sendPayloadRequest(domain: UniversalMessage_Domain, payload: Data) throws {
        let address = getNextAddress()
        let uuid = Data.random(length: 16)
        var message = UniversalMessage_RoutableMessage()
        message.toDestination.domain = domain
        message.fromDestination.routingAddress = address
        message.uuid = uuid
        message.flags = 1 << UniversalMessage_Flags.flagEncryptResponse.rawValue
        responseHandlers[address] = handlePayloadResponse(message:)
        logger.info("tesla-vehicle: Payload \(payload.hexString())")
        try sign(message: &message, payload: payload)
        try sendMessage(message: message)
    }

    private func handlePayloadResponse(message: UniversalMessage_RoutableMessage) throws {
        logger.info("tesla-vehicle: Got payload status \(message.signedMessageStatus.signedMessageFault)")
        try logger.info("tesla-vehicle: Got payload for \(message.jsonString())")
    }

    private func handleMessage(message: Data) throws {
        receivedData += message
        let reader = ByteArray(data: receivedData)
        let size = try reader.readUInt16()
        if reader.bytesAvailable < size {
            return
        }
        let payload = try reader.readBytes(Int(size))
        // logger.info("tesla-vehicle: Got \(payload.hexString()) of \(payload.count) bytes")
        if reader.bytesAvailable > 0 {
            receivedData = try reader.readBytes(reader.bytesAvailable)
        }
        let message = try UniversalMessage_RoutableMessage(serializedBytes: payload)
        // logger.info("tesla-vehicle: Got \(try message.jsonString())")
        switch message.toDestination.subDestination {
        case let .routingAddress(address):
            try responseHandlers[address]?(message)
        default:
            logger.info("tesla-vehicle: Unexpected non-routing address")
        }
    }

    private func sendMessage(message: UniversalMessage_RoutableMessage) throws {
        // logger.info("tesla-vehicle: Sending \(try message.jsonString())")
        let message = try message.serializedData()
        sendData(message: message)
    }

    private func sendData(message: Data) {
        guard let toVehicleCharacteristic else {
            return
        }
        // logger.info("tesla-vehicle: Sending \(message.hexString())")
        let writer = ByteArray()
        writer.writeUInt16(UInt16(message.count))
        writer.writeBytes(message)
        let data = writer.data
        let blockLength = 20
        for offset in stride(from: 0, to: data.count, by: blockLength) {
            let block = data[offset ..< min(offset + blockLength, data.count)]
            vehiclePeripheral?.writeValue(block, for: toVehicleCharacteristic, type: .withResponse)
        }
    }

    private func sign(message: inout UniversalMessage_RoutableMessage, payload: Data) throws {
        guard let sessionInfo else {
            return
        }
        logger.info("tesla-vehicle: Counter \(sessionInfo.counter)")
        message.signatureData.signerIdentity.publicKey = privateKey.pubKeyBytes
        message.signatureData.aesGcmPersonalizedData.epoch = sessionInfo.epoch
        message.signatureData.aesGcmPersonalizedData.counter = sessionInfo.counter + 1
        message.signatureData.aesGcmPersonalizedData.expiresAt = sessionInfo.clockTime + 15
        let key = try createSymmetricKey(vehiclePublicKey: sessionInfo.publicKey)
        let metadataHash = try createMetadata(message)
        let encrypted = try AES.GCM.seal(payload, using: key, authenticating: metadataHash)
        message.signatureData.aesGcmPersonalizedData.nonce = Data(encrypted.nonce.makeIterator())
        message.signatureData.aesGcmPersonalizedData.tag = encrypted.tag
        message.payload = .protobufMessageAsBytes(encrypted.ciphertext)
    }

    private func createSymmetricKey(vehiclePublicKey: Data) throws -> SymmetricKey {
        let vehicleKeyDer = makeDer(publicBytes: vehiclePublicKey)
        let publicKey = try P256.KeyAgreement.PublicKey(derRepresentation: vehicleKeyDer)
        let privateKey = try P256.KeyAgreement.PrivateKey(pemRepresentation: privateKeyPem)
        let shared = try privateKey.sharedSecretFromKeyAgreement(with: publicKey)
        let sharedData = shared.withUnsafeBytes { buffer in
            Data(bytes: buffer.baseAddress!, count: buffer.count)
        }
        let sharedSecret = SHA1(data: sharedData).digest[0 ..< 16]
        return SymmetricKey(data: sharedSecret)
    }

    private func createMetadata(_ message: UniversalMessage_RoutableMessage) throws -> Data {
        let metadata = Metadata()
        try metadata.addUInt8(tag: .signatureType, UInt8(Signatures_SignatureType.aesGcmPersonalized.rawValue))
        try metadata.addUInt8(tag: .domain, UInt8(message.toDestination.domain.rawValue))
        try metadata.add(tag: .personalization, vin.utf8Data)
        try metadata.add(tag: .epoch, message.signatureData.aesGcmPersonalizedData.epoch)
        try metadata.addUInt32(tag: .expiresAt, message.signatureData.aesGcmPersonalizedData.expiresAt)
        try metadata.addUInt32(tag: .counter, message.signatureData.aesGcmPersonalizedData.counter)
        try metadata.addUInt32(tag: .flags, message.flags)
        return metadata.finalize(message: Data())
    }

    private func makeDer(publicBytes: Data) -> Data {
        // Dirty, dirty, dirty...
        let derStuff = Data([
            0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2A, 0x86,
            0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x08, 0x2A,
            0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07, 0x03,
            0x42, 0x00,
        ])
        return derStuff + publicBytes
    }
}

extension TeslaVehicle: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            centralManager?.scanForPeripherals(withServices: nil)
        default:
            break
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi _: NSNumber
    ) {
        guard let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String else {
            return
        }
        guard localName == self.localName() else {
            return
        }
        logger.debug("tesla-vehicle: Connecting to \(localName)")
        central.stopScan()
        vehiclePeripheral = peripheral
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
        setState(state: .connecting)
    }

    func centralManager(_: CBCentralManager, didFailToConnect _: CBPeripheral, error _: Error?) {
        logger.debug("tesla-vehicle: Connect failure")
    }

    func centralManager(_: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.debug("tesla-vehicle: Connected")
        peripheral.discoverServices([vehicleServiceUuid])
    }

    func centralManager(_: CBCentralManager, didDisconnectPeripheral _: CBPeripheral, error _: Error?) {
        logger.debug("tesla-vehicle: Disconnected")
    }
}

extension TeslaVehicle: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices _: Error?) {
        guard let peripheralServices = peripheral.services else {
            logger.error("tesla-vehicle: No services found")
            return
        }
        for service in peripheralServices {
            peripheral.discoverCharacteristics([toVehicleUuid, fromVehicleUuid], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error _: Error?) {
        for characteristic in service.characteristics ?? [] {
            if characteristic.uuid == toVehicleUuid {
                toVehicleCharacteristic = characteristic
            } else if characteristic.uuid == fromVehicleUuid {
                fromVehicleCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        do {
            try startHandshake()
        } catch {
            logger.info("tesla-vehicle: Failed to start handshake \(error)")
        }
    }

    func peripheral(_: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error _: Error?) {
        guard let value = characteristic.value else {
            return
        }
        do {
            try handleMessage(message: value)
        } catch {
            logger.info("tesla-vehicle: Message handling error \(error)")
        }
    }

    func peripheral(_: CBPeripheral, didUpdateNotificationStateFor _: CBCharacteristic, error _: Error?) {}

    func peripheralIsReady(toSendWriteWithoutResponse _: CBPeripheral) {}
}

private class Metadata {
    private var writer = ByteArray()
    private var lastTag: Signatures_Tag?

    func add(tag: Signatures_Tag, _ value: Data) throws {
        if let lastTag {
            guard tag.rawValue > lastTag.rawValue else {
                throw "Must be added in increasing tags order"
            }
        }
        guard value.count <= 255 else {
            throw "Metadata value too long \(value.count)"
        }
        lastTag = tag
        writer.writeUInt8(UInt8(tag.rawValue))
        writer.writeUInt8(UInt8(value.count))
        writer.writeBytes(value)
    }

    func addUInt8(tag: Signatures_Tag, _ value: UInt8) throws {
        try add(tag: tag, Data([value]))
    }

    func addUInt32(tag: Signatures_Tag, _ value: UInt32) throws {
        var data = Data(count: 4)
        data.setUInt32Be(value: value)
        try add(tag: tag, data)
    }

    func finalize(message: Data) -> Data {
        writer.writeUInt8(UInt8(Signatures_Tag.end.rawValue))
        writer.writeBytes(message)
        return Data(SHA256.hash(data: writer.data))
    }
}
