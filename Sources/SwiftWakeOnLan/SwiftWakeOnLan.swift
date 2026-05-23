// The Swift Programming Language
// https://docs.swift.org/swift-book

import Darwin
import Foundation

//
//  SwiftWakeOnLan.swift
//

@main
struct SwiftWakeOnLan {

    static func main() {
        do {
            let configuration = try Configuration.parse(
                arguments: Array(CommandLine.arguments.dropFirst())
            )

            let mac = try resolveMAC(from: configuration.target)

            let packet = WakeOnLAN.magicPacket(mac: mac)

            try WakeOnLAN.send(
                packet: packet,
                broadcast: configuration.broadcast,
                port: configuration.port
            )

            let message =
                "Wake-on-LAN packet sent to \(WakeOnLAN.formatMAC(mac)) "
                + "via \(configuration.broadcast):\(configuration.port)"

            print(message)

        } catch let error as WakeOnLANError {
            print(error.localizedDescription)
            exit(1)

        } catch {
            print(error.localizedDescription)
            exit(1)
        }
    }

    static func resolveMAC(from target: String) throws -> [UInt8] {

        if NetworkTools.isIPAddress(target) {

            guard let mac = ARPResolver.macAddress(for: target) else {
                throw WakeOnLANError.macResolutionFailed(target)
            }

            print(
                "Resolved \(target) -> \(WakeOnLAN.formatMAC(mac))"
            )

            return mac
        }

        guard let mac = WakeOnLAN.parseMAC(target) else {
            throw WakeOnLANError.invalidTarget(target)
        }

        return mac
    }
}

//
// MARK: - Configuration
//

struct Configuration {

    let target: String
    let broadcast: String
    let port: UInt16

    static func parse(arguments: [String]) throws -> Configuration {

        guard let target = arguments.first else {
            throw WakeOnLANError.usage
        }

        var broadcast = "255.255.255.255"
        var port: UInt16 = 9

        var iterator = arguments.dropFirst().makeIterator()

        while let argument = iterator.next() {

            switch argument {

            case "--broadcast":
                guard let value = iterator.next() else {
                    throw WakeOnLANError.usage
                }

                broadcast = value

            case "--port":
                guard
                    let value = iterator.next(),
                    let parsedPort = UInt16(value)
                else {
                    throw WakeOnLANError.usage
                }

                port = parsedPort

            default:
                throw WakeOnLANError.usage
            }
        }

        return Configuration(
            target: target,
            broadcast: broadcast,
            port: port
        )
    }
}

//
// MARK: - Errors
//

enum WakeOnLANError: LocalizedError {

    case usage
    case invalidTarget(String)
    case macResolutionFailed(String)
    case socketCreationFailed
    case sendFailed

    var errorDescription: String? {

        switch self {

        case .usage:
            return """
                Usage:
                  wakeonlan <mac-address|ip-address> [--broadcast 255.255.255.255] [--port 9]
                """

        case .invalidTarget(let target):
            return "Invalid MAC address or IP address: \(target)"

        case .macResolutionFailed(let target):
            return """
                Failed to resolve MAC address via ARP for IP: \(target)
                Hint: the target usually needs to exist in the ARP table first.
                """

        case .socketCreationFailed:
            return "Failed to create UDP socket"

        case .sendFailed:
            return "Failed to send Wake-on-LAN packet"
        }
    }
}

//
// MARK: - WakeOnLAN
//

enum WakeOnLAN {

    static func parseMAC(_ input: String) -> [UInt8]? {

        let cleaned =
            input
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: ".", with: "")

        guard cleaned.count == 12 else {
            return nil
        }

        var bytes: [UInt8] = []
        var index = cleaned.startIndex

        for _ in 0..<6 {

            let next = cleaned.index(index, offsetBy: 2)

            let part = String(cleaned[index..<next])

            guard let byte = UInt8(part, radix: 16) else {
                return nil
            }

            bytes.append(byte)

            index = next
        }

        return bytes
    }

    static func formatMAC(_ mac: [UInt8]) -> String {

        mac
            .map { String(format: "%02X", $0) }
            .joined(separator: ":")
    }

    static func magicPacket(mac: [UInt8]) -> [UInt8] {

        Array(repeating: 0xFF, count: 6)
            + Array(repeating: mac, count: 16).flatMap { $0 }
    }

    static func send(
        packet: [UInt8],
        broadcast: String,
        port: UInt16
    ) throws {

        let socketFileDescriptor = socket(
            AF_INET,
            SOCK_DGRAM,
            IPPROTO_UDP
        )

        guard socketFileDescriptor >= 0 else {
            throw WakeOnLANError.socketCreationFailed
        }

        defer {
            close(socketFileDescriptor)
        }

        try enableBroadcast(on: socketFileDescriptor)

        var address = makeSocketAddress(
            broadcast: broadcast,
            port: port
        )

        let sent = sendPacket(
            packet,
            socket: socketFileDescriptor,
            address: &address
        )

        guard sent == packet.count else {
            throw WakeOnLANError.sendFailed
        }
    }

    private static func enableBroadcast(
        on socket: Int32
    ) throws {

        var yes: Int32 = 1

        setsockopt(
            socket,
            SOL_SOCKET,
            SO_BROADCAST,
            &yes,
            socklen_t(MemoryLayout<Int32>.size)
        )
    }

    private static func makeSocketAddress(
        broadcast: String,
        port: UInt16
    ) -> sockaddr_in {

        var address = sockaddr_in()

        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = port.bigEndian
        address.sin_addr.s_addr = inet_addr(broadcast)

        return address
    }

    private static func sendPacket(
        _ packet: [UInt8],
        socket: Int32,
        address: inout sockaddr_in
    ) -> Int {

        packet.withUnsafeBytes { pointer in

            withUnsafePointer(to: &address) {

                $0.withMemoryRebound(
                    to: sockaddr.self,
                    capacity: 1
                ) {

                    sendto(
                        socket,
                        pointer.baseAddress,
                        packet.count,
                        0,
                        $0,
                        socklen_t(MemoryLayout<sockaddr_in>.size)
                    )
                }
            }
        }
    }
}

//
// MARK: - NetworkTools
//

enum NetworkTools {

    static func isIPAddress(_ input: String) -> Bool {

        var address = in_addr()

        return input.withCString {
            inet_pton(AF_INET, $0, &address) == 1
        }
    }
}

//
// MARK: - ARPResolver
//

enum ARPResolver {

    static func macAddress(
        for ipAddress: String
    ) -> [UInt8]? {

        let process = Process()

        process.executableURL = URL(
            fileURLWithPath: "/usr/sbin/arp"
        )

        process.arguments = ["-n", ipAddress]

        let pipe = Pipe()

        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            return nil
        }

        process.waitUntilExit()

        let data = pipe.fileHandleForReading
            .readDataToEndOfFile()

        guard
            let output = String(
                data: data,
                encoding: .utf8
            )
        else {
            return nil
        }

        return extractMAC(from: output)
    }

    static func extractMAC(
        from arpOutput: String
    ) -> [UInt8]? {

        let regex =
            /(([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2})/

        guard
            let match = arpOutput.firstMatch(of: regex)
        else {
            return nil
        }

        return WakeOnLAN.parseMAC(
            String(match.output.0)
        )
    }
}
