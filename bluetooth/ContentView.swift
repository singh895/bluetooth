//import SwiftUI
//import CoreBluetooth
//
//class BluetoothViewModel: NSObject, ObservableObject {
//    private var centralManager: CBCentralManager?
//    private var peripherals: [CBPeripheral] = []
//    @Published var peripheralNames: [String] = []
//    
//    @Published var selectedPeripheral: CBPeripheral? // Added property to store the selected peripheral
//    
//    override init() {
//        super.init()
//        self.centralManager = CBCentralManager(delegate: self, queue: .main)
//    }
//    
//    func getPeripheral(withName name: String) -> CBPeripheral? {
//        return peripherals.first { $0.name == name }
//    }
//    private var selectedCharacteristic: CBCharacteristic?
//    private var dataToSend: String = "123" // Replace with the 3-digit number you want to send
//
//    func connectToPeripheral() {
//        guard let selectedPeripheral = selectedPeripheral else { return }
//        centralManager?.connect(selectedPeripheral, options: nil)
//    }
//
//    func sendBluetoothData() {
//        guard let selectedPeripheral = selectedPeripheral,
//              let selectedCharacteristic = selectedCharacteristic,
//              let data = dataToSend.data(using: .utf8) else { return }
//
//        selectedPeripheral.writeValue(data, for: selectedCharacteristic, type: .withResponse)
//    }
//}
//
//extension BluetoothViewModel: CBCentralManagerDelegate {
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        if central.state == .poweredOn {
//            self.centralManager?.scanForPeripherals(withServices: nil)
//        }
//    }
//    
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        if let peripheralName = peripheral.name, !peripheralName.isEmpty {
//            if !peripherals.contains(peripheral) {
//                self.peripherals.append(peripheral)
//                self.peripheralNames.append(peripheralName)
//            }
//        }
//    }
//}
//
//struct ContentView: View {
//    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
//    
//    var body: some View {
//        NavigationView {
//            List(bluetoothViewModel.peripheralNames, id: \.self) { peripheralName in
//                NavigationLink(
//                    destination: Text("Connect to \(peripheralName)")
//                        .onAppear {
//                            bluetoothViewModel.selectedPeripheral = bluetoothViewModel.getPeripheral(withName: peripheralName)
//                        },
//                    label: {
//                        Text(peripheralName)
//                    })
//            }
//            .navigationTitle("Peripherals")
//        }
//    }
//}
//
//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}


import SwiftUI
import CoreBluetooth

class BluetoothViewModel: NSObject, ObservableObject {
    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var peripherals: [CBPeripheral] = []
    private var selectedCharacteristic: CBCharacteristic?
    
    @Published var peripheralNames: [String] = []
    @Published var isDeviceConnected: Bool = false
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    func getPeripheral(withName name: String) -> CBPeripheral? {
        return centralManager?.retrievePeripherals(withIdentifiers: [UUID(uuidString: name) ?? UUID()]).first
    }
    
    func connectToPeripheral(peripheral: CBPeripheral) {
        centralManager?.connect(peripheral, options: nil)
    }
    
    func sendBluetoothData(dataToSend: String) {
        guard let connectedPeripheral = connectedPeripheral,
              let selectedCharacteristic = selectedCharacteristic,
              let data = dataToSend.data(using: .utf8) else { return }
        
        connectedPeripheral.writeValue(data, for: selectedCharacteristic, type: .withResponse)
    }
}

extension BluetoothViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager?.scanForPeripherals(withServices: nil)
        }
    }
    

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let peripheralName = peripheral.name, !peripheralName.isEmpty {
            if !peripherals.contains(peripheral) {
                self.peripherals.append(peripheral)
                self.peripheralNames.append(peripheralName)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        connectedPeripheral = peripheral
        isDeviceConnected = true
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        isDeviceConnected = false
    }
}

extension BluetoothViewModel: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.properties.contains(.write) {
                selectedCharacteristic = characteristic
                break
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
    @State private var dataToSend: String = ""
    
    var body: some View {
        NavigationView {
//            if bluetoothViewModel.isDeviceConnected {
            VStack {
                List(bluetoothViewModel.peripheralNames, id: \.self) { peripheralName in
                    NavigationLink(
                        destination: Text("Connect to \(peripheralName)")
                            .onAppear {
                                if let peripheral = bluetoothViewModel.getPeripheral(withName: peripheralName) {
                                    bluetoothViewModel.connectToPeripheral(peripheral: peripheral)
                                    
                                }
                            },
                        label: {
                            Text(peripheralName)
                        })
                }
                .navigationTitle("Peripherals")
                TextField("Enter 3-digit number", text: $dataToSend)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    bluetoothViewModel.sendBluetoothData(dataToSend: dataToSend)
                }) {
                    Text("Send Data")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Send Data")
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


//import SwiftUI  //has issues second best
//import CoreBluetooth
//
//class BluetoothViewModel: NSObject, ObservableObject {
//    private var centralManager: CBCentralManager?
//    private var connectedPeripheral: CBPeripheral?
//    private var selectedCharacteristic: CBCharacteristic?
//    
//    @Published var peripheralNames: [String] = []
//    @Published var isDeviceConnected: Bool = false
//    
//    override init() {
//        super.init()
//        self.centralManager = CBCentralManager(delegate: self, queue: .main)
//    }
//    
//    func getPeripheral(withName name: String) -> CBPeripheral? {
//        return centralManager?.retrievePeripherals(withIdentifiers: [UUID(uuidString: name) ?? UUID()]).first
//    }
//    
//    func connectToPeripheral(peripheral: CBPeripheral) {
//        centralManager?.connect(peripheral, options: nil)
//    }
//    
//    func sendBluetoothData(dataToSend: String) {
//        guard let connectedPeripheral = connectedPeripheral,
//              let selectedCharacteristic = selectedCharacteristic,
//              let data = dataToSend.data(using: .utf8) else { return }
//        
//        connectedPeripheral.writeValue(data, for: selectedCharacteristic, type: .withResponse)
//    }
//}
//
//extension BluetoothViewModel: CBCentralManagerDelegate {
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        if central.state == .poweredOn {
//            self.centralManager?.scanForPeripherals(withServices: nil)
//        }
//    }
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        if let peripheralIdentifier = peripheral.identifier.uuidString as String? {
//            if let peripheralName = peripheral.name, !peripheralName.isEmpty {
//                if !peripheralNames.contains(peripheralIdentifier) {
//                    
//                    self.peripheralNames.append(peripheralName)
//                }
//            }
//        }
//    }
////    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
////        if let peripheralName = peripheral.name, !peripheralName.isEmpty {
////            if !peripherals.contains(peripheral) {
////                self.peripherals.append(peripheral)
////                self.peripheralNames.append(peripheralName)
////            }
////        }
////    }
//    
//    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//        peripheral.delegate = self
//        peripheral.discoverServices(nil)
//        connectedPeripheral = peripheral
//        isDeviceConnected = true
//    }
//    
//    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
//        connectedPeripheral = nil
//        isDeviceConnected = false
//    }
//}
//
//extension BluetoothViewModel: CBPeripheralDelegate {
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//        guard let services = peripheral.services else { return }
//        for service in services {
//            peripheral.discoverCharacteristics(nil, for: service)
//        }
//    }
//    
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
//        guard let characteristics = service.characteristics else { return }
//        for characteristic in characteristics {
//            if characteristic.properties.contains(.write) {
//                selectedCharacteristic = characteristic
//                break
//            }
//        }
//    }
//}
//
//struct ContentView: View {
//    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
//    @State private var dataToSend: String = ""
//    
//    var body: some View {
//        NavigationView {
//            if bluetoothViewModel.isDeviceConnected {
//                VStack {
//                    TextField("Enter 3-digit number", text: $dataToSend)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .padding()
//                    
//                    Button(action: {
//                        bluetoothViewModel.sendBluetoothData(dataToSend: dataToSend)
//                    }) {
//                        Text("Send Data")
//                            .padding()
//                            .background(Color.blue)
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                    }
//                }
//                .navigationTitle("Send Data")
//            } else {
//                List(bluetoothViewModel.peripheralNames, id: \.self) { peripheralName in
//                    NavigationLink(
//                        destination: Text("Connect to \(peripheralName)")
//                            .onAppear {
//                                if let peripheral = bluetoothViewModel.getPeripheral(withName: peripheralName) {
//                                    bluetoothViewModel.connectToPeripheral(peripheral: peripheral)
//                                }
//                            },
//                        label: {
//                            Text(peripheralName)
//                        })
//                }
//                .navigationTitle("Peripherals")
//            }
//        }
//    }
//}


//import SwiftUI   //so far best
//import CoreBluetooth
//
//class BluetoothViewModel: NSObject, ObservableObject {
//    private var centralManager: CBCentralManager?
//    private var peripherals: [CBPeripheral] = []
//    @Published var peripheralNames: [String] = []
//    
//    @Published var selectedPeripheral: CBPeripheral? // Added property to store the selected peripheral
//    private var selectedCharacteristic: CBCharacteristic?
//    
//    override init() {
//        super.init()
//        self.centralManager = CBCentralManager(delegate: self, queue: .main)
//    }
//    
//    func getPeripheral(withName name: String) -> CBPeripheral? {
//        return peripherals.first { $0.name == name }
//    }
//    
//    func connectToPeripheral() {
//        guard let selectedPeripheral = selectedPeripheral else { return }
//        centralManager?.connect(selectedPeripheral, options: nil)
//    }
//    
//    func sendBluetoothData(dataToSend: String) {
//        guard let selectedPeripheral = selectedPeripheral,
//              let selectedCharacteristic = selectedCharacteristic,
//              let data = dataToSend.data(using: .utf8) else { return }
//        
//        selectedPeripheral.writeValue(data, for: selectedCharacteristic, type: .withResponse)
//    }
//}
//
//extension BluetoothViewModel: CBCentralManagerDelegate {
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        if central.state == .poweredOn {
//            self.centralManager?.scanForPeripherals(withServices: nil)
//        }
//    }
//    
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        if let peripheralName = peripheral.name, !peripheralName.isEmpty {
//            if !peripherals.contains(peripheral) {
//                self.peripherals.append(peripheral)
//                self.peripheralNames.append(peripheralName)
//            }
//        }
//    }
//    
//    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//        peripheral.delegate = self
//        peripheral.discoverServices(nil)
//    }
//}
//
//extension BluetoothViewModel: CBPeripheralDelegate {
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//        guard let services = peripheral.services else { return }
//        for service in services {
//            peripheral.discoverCharacteristics(nil, for: service)
//        }
//    }
//    
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
//        guard let characteristics = service.characteristics else { return }
//        for characteristic in characteristics {
//            if characteristic.properties.contains(.write) {
//                selectedCharacteristic = characteristic
//                break
//            }
//        }
//    }
//}
//struct ContentView: View {
//    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
//    @State private var dataToSend: String = ""
//    @State private var isDeviceSelected: Bool = false
//    
//    var body: some View {
//        NavigationView {
//            if isDeviceSelected {
//                VStack {
//                    TextField("Enter 3-digit number", text: $dataToSend)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .padding()
//                    
//                    Button(action: {
//                        bluetoothViewModel.sendBluetoothData(dataToSend: dataToSend)
//                    }) {
//                        Text("Send Data")
//                            .padding()
//                            .background(Color.blue)
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                    }
//                }
//                .navigationTitle("Send Data")
//            } 
//            else {
//                List(bluetoothViewModel.peripheralNames, id: \.self) { peripheralName in
//                    NavigationLink(
//                        destination: Text("Connect to \(peripheralName)")
//                            .onAppear {
//                                bluetoothViewModel.selectedPeripheral = bluetoothViewModel.getPeripheral(withName: peripheralName)
//                                isDeviceSelected = true
//                            },
//                        label: {
//                            Text(peripheralName)
//                        })
//                }
//                .navigationTitle("Peripherals")
//            }
//        }
//    }
//}


//struct ContentView: View {
//    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
//    @State private var dataToSend: String = ""
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                List(bluetoothViewModel.peripheralNames, id: \.self) { peripheralName in
//                    NavigationLink(
//                        destination: Text("Connect to \(peripheralName)")
//                            .onAppear {
//                                bluetoothViewModel.selectedPeripheral = bluetoothViewModel.getPeripheral(withName: peripheralName)
//                            },
//                        label: {
//                            Text(peripheralName)
//                        })
//                }
//                .navigationTitle("Peripherals")
//                
//                TextField("Enter 3-digit number", text: $dataToSend)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .padding()
//                
//                Button(action: {
//                    bluetoothViewModel.sendBluetoothData(dataToSend: dataToSend)
//                }) {
//                    Text("Send Data")
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                }
//            }
//        }
//    }
//}

