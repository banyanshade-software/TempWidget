
#!/usr/bin/env python3
# File: tp357.py

import sys
import argparse
import asyncio
import simplepyble 

#!/usr/bin/env python3
# File: tp357.pypip


def scan_with_simplepyble(timeout):
    adapters = simplepyble.Adapter.get_adapters()

    if len(adapters) == 0:
        print("No adapters found")
        return

    for adapter in adapters:
        print(f"Adapter: {adapter.identifier()} [{adapter.address()}]")
   
    adapter = adapters[0]
    print(f"Using adapter: {adapter.identifier()} [{adapter.address()}]")
   
   
    adapter.set_callback_on_scan_start(lambda: print("Scan started."))
    adapter.set_callback_on_scan_stop(lambda: print("Scan complete."))
    adapter.set_callback_on_scan_found(lambda peripheral: print(f"Found {peripheral.identifier()} [{peripheral.address()}]"))

    adapter.scan_for(timeout*1000)
    peripherals = adapter.scan_get_results()
    
    print("full list of found peripheral:")
    dev = None
    for i, peripheral in enumerate(peripherals):
        print(f"{i}: {peripheral.identifier()} [{peripheral.address()}]")
        # name shall start with "TP357"
        if peripheral.identifier().startswith("TP357"):
            print(f"FOUND TP357 peripheral: {peripheral.identifier()} [{peripheral.address()}]")
            dev = peripheral
            break
    if dev is None:
        print("No TP357 peripheral found.")
        return

    dev.connect()
    print("Connected.")
    services = dev.services()
    for service in services:
        print(f"Service: {service.uuid()}")
        for characteristic in service.characteristics():
            print(f"    Characteristic: {characteristic.uuid()}")

            capabilities = " ".join(characteristic.capabilities())
            print(f"    Capabilities: {capabilities}")

    # define constant for service and characteristic UUIDs
    TP357_PRIVATE_SERVICE_UUID = "00010203-0405-0607-0809-0a0b0c0d1910"
    TP357_READ_CHARACTERISTIC_UUID = "00010203-0405-0607-0809-0a0b0c0d2b10"
    TP357_WRITE_CHARACTERISTIC_UUID = "00010203-0405-0607-0809-0a0b0c0d2b11"
    
    c = dev.read(TP357_PRIVATE_SERVICE_UUID, TP357_READ_CHARACTERISTIC_UUID) 
    print(f"Read from TP357: {c}")

    cmd = b"\xa7\x00\x00\x00\x00\x7a" # https://github.com/alexpacini/tpy357/blob/master/tpy357/__init__.py
    dev.write_command(TP357_PRIVATE_SERVICE_UUID, TP357_WRITE_CHARACTERISTIC_UUID, cmd) #bytearray([0x01, 0x02, 0x03]))
    c = dev.read(TP357_PRIVATE_SERVICE_UUID, TP357_READ_CHARACTERISTIC_UUID) 
    print(f"Read from TP357: {c}")

    c = dev.read(TP357_PRIVATE_SERVICE_UUID, TP357_READ_CHARACTERISTIC_UUID) 
    print(f"Read from TP357: {c}")

    dev.disconnect()
    print("Disconnected.")





def main():
   scan_with_simplepyble(10);

if __name__ == "__main__":
    main()