import Testing

@testable import swol

@Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    // Swift Testing Documentation
    // https://swiftpackageindex.com/swiftlang/swift-testing/documentation
}

struct WakeOnLANTests {

    @Test
    func parseMACWithColonNotation() {

        let result = WakeOnLAN.parseMAC(
            "AA:BB:CC:DD:EE:FF"
        )

        #expect(
            result == [
                0xAA,
                0xBB,
                0xCC,
                0xDD,
                0xEE,
                0xFF,
            ])
    }

    @Test
    func parseMACWithDashNotation() {

        let result = WakeOnLAN.parseMAC(
            "AA-BB-CC-DD-EE-FF"
        )

        #expect(result != nil)
    }

    @Test
    func parseMACFailsForInvalidInput() {

        let result = WakeOnLAN.parseMAC(
            "INVALID"
        )

        #expect(result == nil)
    }

    @Test
    func formatMACProducesUppercaseOutput() {

        let mac: [UInt8] = [
            0xaa,
            0xbb,
            0xcc,
            0xdd,
            0xee,
            0xff,
        ]

        let formatted = WakeOnLAN.formatMAC(mac)

        #expect(
            formatted == "AA:BB:CC:DD:EE:FF"
        )
    }

    @Test
    func magicPacketHasCorrectLength() {

        let mac: [UInt8] = [
            1, 2, 3, 4, 5, 6,
        ]

        let packet = WakeOnLAN.magicPacket(
            mac: mac
        )

        #expect(packet.count == 102)
    }

    @Test
    func magicPacketStartsWithFFHeader() {

        let mac: [UInt8] = [
            1, 2, 3, 4, 5, 6,
        ]

        let packet = WakeOnLAN.magicPacket(
            mac: mac
        )

        #expect(
            Array(packet.prefix(6))
                == Array(repeating: 0xFF, count: 6)
        )
    }

    @Test
    func detectValidIPAddress() {

        let result = NetworkTools.isIPAddress(
            "192.168.1.10"
        )

        #expect(result == true)
    }

    @Test
    func detectInvalidIPAddress() {

        let result = NetworkTools.isIPAddress(
            "not-an-ip"
        )

        #expect(result == false)
    }

    @Test
    func extractMACFromARPOutput() {

        let arpOutput =
            "? (192.168.1.10) at aa:bb:cc:dd:ee:ff on en0 ifscope [ethernet]"

        let mac = ARPResolver.extractMAC(
            from: arpOutput
        )

        #expect(
            mac == [
                0xAA,
                0xBB,
                0xCC,
                0xDD,
                0xEE,
                0xFF,
            ]
        )
    }

    @Test
    func parseConfiguration() throws {

        let configuration =
            try Configuration.parse(
                arguments: [
                    "192.168.1.10",
                    "--broadcast",
                    "192.168.1.255",
                    "--port",
                    "7",
                ]
            )

        #expect(
            configuration.target
                == "192.168.1.10"
        )

        #expect(
            configuration.broadcast
                == "192.168.1.255"
        )

        #expect(configuration.port == 7)
    }
}
