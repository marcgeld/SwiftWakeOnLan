# SwiftWakeOnLan
A lightweight Wake-on-LAN (WOL) command-line utility written in Swift.

SwiftWakeOnLan sends standard Wake-on-LAN magic packets over UDP to power on devices remotely on a local network.

The tool supports:

- MAC address targets
- IP address targets via ARP lookup
- Custom broadcast addresses
- Custom UDP ports
- Zero external dependencies
- Swift Package Manager builds
- Unit tests using Swift Testing

## Features

- Minimal and dependency-free
- Native Swift implementation
- Supports standard WOL magic packets
- Works on macOS
- Simple CLI interface
- ARP-based IP → MAC resolution

## Requirements

- macOS
- Swift 6+

## Download

Prebuilt binaries are available from the GitHub Releases page.

## Build

Build a debug version:

```bash
swift build
```

Build an optimized release version:

```bash
swift build -c release
```

The release binary will be available at:

```text
.build/release/swol
```

## Run Locally

Run using Swift Package Manager:

```bash
swift run swol AA:BB:CC:DD:EE:FF
```

Run using an IP address:

```bash
swift run swol 192.168.1.100
```

Use a custom broadcast address:

```bash
swift run swol 192.168.1.100 --broadcast 192.168.1.255
```

Use a custom UDP port:

```bash
swift run swol AA:BB:CC:DD:EE:FF --port 7
```

Run the compiled release binary directly:

```bash
.build/release/swol AA:BB:CC:DD:EE:FF
```

## Usage

Wake a device using a MAC address:

```bash
swol AA:BB:CC:DD:EE:FF
```

Wake a device using an IP address:

```bash
swol 192.168.1.100
```

Use a custom broadcast address:

```bash
swol 192.168.1.100 --broadcast 192.168.1.255
```

Use a custom UDP port:

```bash
swol AA:BB:CC:DD:EE:FF --port 7
```

## ARP Resolution Notes

When using an IP address, SwiftWakeOnLan attempts to resolve the MAC address using the local ARP table.

This usually requires that:

- the target device has been online recently
- the device exists in the ARP cache
- the target is on the same local network

If ARP resolution fails, use the MAC address directly.

## Run Tests

```bash
swift test
```

Run tests with verbose output:

```bash
swift test --verbose
```

## Example Output

```text
Resolved 192.168.1.100 -> AA:BB:CC:DD:EE:FF

Wake-on-LAN packet sent to AA:BB:CC:DD:EE:FF
via 255.255.255.255:9
```

## License

Apache License 2.0 License
