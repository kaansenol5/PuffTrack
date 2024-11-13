//
//  SocialsViewModel.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 14.09.2024.
//

import Foundation
import SocketIO
import KeychainAccess

class SocialsViewModel: ObservableObject {
    // MARK: - Properties
    
    private var socketManager: SocketManager?
    private var socket: SocketIOClient?
    @Published var isErrorDisplayed: Bool = false {
        didSet {
            print("isErrorDisplayed changed to: \(isErrorDisplayed)")
            print(errorMessage)
        }
    }
    @Published var errorMessage: String = ""
    var lastSyncedPuffs: [String] = []
    @Published var serverData: FullSyncResponse?
    private let baseURL = "https://api.pufftrack.app"
    private var token: String?
    var serverPuffCount: Int = 0
    private let keychainServiceName = "com.kaansenol.PuffTrack" // Replace with your app's bundle identifier
    private let tokenKey = "authToken"
    @Published var accessedData: [String: Any]?

    // MARK: - Initialization
    
    init() {
        if let savedToken = loadTokenFromKeychain() {
            self.token = savedToken
            connectSocket()
        } else {
            print("No token found in Keychain")
        }
    }
    
    // MARK: - Authentication Methods
    
    func performRequest(endpoint: String, httpMethod: String, body: [String: Any], completion: @escaping (Result<[String: Any], Error>) -> Void) {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = httpMethod
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network errors
            if let error = error {
                DispatchQueue.main.async {
                    print("Network Error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
                return
            }
            
            // Check HTTP status code
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
                DispatchQueue.main.async {
                    print("Error: Invalid response type")
                    completion(.failure(error))
                }
                return
            }
            
            // Handle HTTP errors
            if !(200...299).contains(httpResponse.statusCode) {
                let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "No error message"
                let error = NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                DispatchQueue.main.async {
                    print("HTTP Error \(httpResponse.statusCode): \(errorMessage)")
                    completion(.failure(error))
                }
                return
            }
            
            // Ensure data is not nil
            guard let data = data else {
                let error = NSError(domain: "NoData", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                DispatchQueue.main.async {
                    print("Error: No data received")
                    completion(.failure(error))
                }
                return
            }
            
            // Parse JSON response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    DispatchQueue.main.async {
                        completion(.success(json))
                    }
                } else {
                    let error = NSError(domain: "InvalidFormat", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
                    DispatchQueue.main.async {
                        print("Error: Invalid response format")
                        completion(.failure(error))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("JSON Parsing Error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    
    func signInWithApple(identityToken: String, userId: String, email: String?, fullName: String?, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "\(baseURL)/apple-signin"
        var body: [String: Any] = ["identityToken": identityToken, "userId": userId]
        
        // Include email and fullName if available
        if let email = email {
            body["email"] = email
        }
        if let fullName = fullName {
            body["fullName"] = fullName
        }
        
        performRequest(endpoint: endpoint, httpMethod: "POST", body: body) { [weak self] result in
            switch result {
            case .success(let json):
                if let token = json["token"] as? String {
                    DispatchQueue.main.async {
                        self?.token = token
                        self?.saveTokenToKeychain(token)
                        self?.connectSocket()
                        completion(.success(token))
                    }
                } else {
                    let error = NSError(domain: "InvalidFormat", code: 0, userInfo: [NSLocalizedDescriptionKey: "Token not found in response"])
                    DispatchQueue.main.async {
                        print("Error: Token not found in response")
                        self?.isErrorDisplayed = true
                        self?.errorMessage = "Unexpected error, please try again later"
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    print("Error: \(error.localizedDescription)")
                    self?.isErrorDisplayed = true
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }

    
    func register(name: String, email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "\(baseURL)/register"
        let body: [String: Any] = ["name": name, "email": email, "password": password]
        
        performRequest(endpoint: endpoint, httpMethod: "POST", body: body) { [weak self] result in
            switch result {
            case .success(let json):
                if let token = json["token"] as? String {
                    DispatchQueue.main.async {
                        self?.token = token
                        self?.saveTokenToKeychain(token)
                        self?.connectSocket()
                        completion(.success(token))
                    }
                } else {
                    let error = NSError(domain: "InvalidFormat", code: 0, userInfo: [NSLocalizedDescriptionKey: "Token not found in response"])
                    DispatchQueue.main.async {
                        print("Error: Token not found in response")
                        self?.isErrorDisplayed = true
                        self?.errorMessage = "Unexpected error, please try again later"
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    print("Error: \(error.localizedDescription)")
                    self?.isErrorDisplayed = true
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }

    func login(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "\(baseURL)/login"
        let body: [String: Any] = ["email": email, "password": password]
        
        performRequest(endpoint: endpoint, httpMethod: "POST", body: body) { [weak self] result in
            switch result {
            case .success(let json):
                if let token = json["token"] as? String {
                    DispatchQueue.main.async {
                        self?.token = token
                        self?.saveTokenToKeychain(token)
                        self?.connectSocket()
                        completion(.success(token))
                    }
                } else {
                    let error = NSError(domain: "InvalidFormat", code: 0, userInfo: [NSLocalizedDescriptionKey: "Token not found in response"])
                    DispatchQueue.main.async {
                        print("Error: Token not found in response")
                        self?.isErrorDisplayed = true
                        self?.errorMessage = "Unexpected error, please try again later"
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    print("Error: \(error.localizedDescription)")
                    self?.isErrorDisplayed = true
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    func changeName(newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let token = self.token else {
            let error = NSError(domain: "Authentication", code: 0, userInfo: [NSLocalizedDescriptionKey: "No token available"])
            completion(.failure(error))
            return
        }
        
        let endpoint = "\(baseURL)/user/name"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PATCH"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["newName": newName]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isErrorDisplayed = true
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    let error = NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
                    self?.isErrorDisplayed = true
                    self?.errorMessage = "Invalid response from server"
                    completion(.failure(error))
                    return
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    // Update the local user data
                    if let userData = self?.serverData?.user {
                        self?.serverData?.user = User(id: userData.id, name: newName, email: userData.email)
                    }
                    completion(.success(()))
                } else {
                    let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error occurred"
                    let error = NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    self?.isErrorDisplayed = true
                    self?.errorMessage = errorMessage
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    func accessData(completion: @escaping (Result<[String: Any], Error>) -> Void) {
         guard let token = self.token else {
             let error = NSError(domain: "Authentication", code: 0, userInfo: [NSLocalizedDescriptionKey: "No token available"])
             completion(.failure(error))
             return
         }

         let endpoint = "\(baseURL)/userData"
         let headers = ["Authorization": "Bearer \(token)"]

         var request = URLRequest(url: URL(string: endpoint)!)
         request.httpMethod = "GET"
         headers.forEach { request.addValue($1, forHTTPHeaderField: $0) }

         URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
             if let error = error {
                 DispatchQueue.main.async {
                     completion(.failure(error))
                 }
                 return
             }

             guard let data = data else {
                 let error = NSError(domain: "NoData", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                 DispatchQueue.main.async {
                     completion(.failure(error))
                 }
                 return
             }

             do {
                 if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                     DispatchQueue.main.async {
                         self?.accessedData = json
                         completion(.success(json))
                     }
                 } else {
                     let error = NSError(domain: "InvalidFormat", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
                     DispatchQueue.main.async {
                         completion(.failure(error))
                     }
                 }
             } catch {
                 DispatchQueue.main.async {
                     completion(.failure(error))
                 }
             }
         }.resume()
     }

     // New function to remove data
     func removeData(completion: @escaping (Result<Void, Error>) -> Void) {
         guard let token = self.token else {
             let error = NSError(domain: "Authentication", code: 0, userInfo: [NSLocalizedDescriptionKey: "No token available"])
             completion(.failure(error))
             return
         }

         let endpoint = "\(baseURL)/deleteUser"
         let headers = ["Authorization": "Bearer \(token)"]

         var request = URLRequest(url: URL(string: endpoint)!)
         request.httpMethod = "DELETE"
         headers.forEach { request.addValue($1, forHTTPHeaderField: $0) }

         URLSession.shared.dataTask(with: request) { data, response, error in
             if let error = error {
                 DispatchQueue.main.async {
                     completion(.failure(error))
                 }
                 return
             }

             guard let httpResponse = response as? HTTPURLResponse else {
                 let error = NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
                 DispatchQueue.main.async {
                     completion(.failure(error))
                 }
                 return
             }

             if (200...299).contains(httpResponse.statusCode) {
                 DispatchQueue.main.async {
                     completion(.success(()))
                 }
             } else {
                 let error = NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to remove data"])
                 DispatchQueue.main.async {
                     completion(.failure(error))
                 }
             }
         }.resume()
     }

    func removeAllPuffs(completion: @escaping (Result<Int, Error>) -> Void) {
        guard let token = self.token else {
            let error = NSError(domain: "Authentication", code: 0, userInfo: [NSLocalizedDescriptionKey: "No token available"])
            completion(.failure(error))
            return
        }
        
        let endpoint = "\(baseURL)/puffs"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            // Handle network errors
            if let error = error {
                DispatchQueue.main.async {
                    self?.isErrorDisplayed = true
                    self?.errorMessage = "Network Error: \(error.localizedDescription)"
                    completion(.failure(error))
                }
                return
            }
            
            // Check HTTP status code
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
                DispatchQueue.main.async {
                    self?.isErrorDisplayed = true
                    self?.errorMessage = "Invalid response from server"
                    completion(.failure(error))
                }
                return
            }
            
            // Handle HTTP errors
            if !(200...299).contains(httpResponse.statusCode) {
                let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                let error = NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                DispatchQueue.main.async {
                    self?.isErrorDisplayed = true
                    self?.errorMessage = "Failed to delete puffs: \(errorMessage)"
                    completion(.failure(error))
                }
                return
            }
            
            // Parse response
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let count = json["count"] as? Int {
                DispatchQueue.main.async {
                    completion(.success(count))
                }
            } else {
                let error = NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse server response"])
                DispatchQueue.main.async {
                    self?.isErrorDisplayed = true
                    self?.errorMessage = "Failed to parse server response"
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - Keychain Methods
    
    private func saveTokenToKeychain(_ token: String) {
        let keychain = Keychain(service: keychainServiceName)
        keychain[tokenKey] = token
    }
    
    private func loadTokenFromKeychain() -> String? {
        let keychain = Keychain(service: keychainServiceName)
        return keychain[tokenKey]
    }
    
    private func deleteTokenFromKeychain() {
        let keychain = Keychain(service: keychainServiceName)
        do {
            try keychain.remove(tokenKey)
        } catch let error {
            print("Error deleting token from Keychain: \(error)")
        }
    }
    
    // MARK: - User Session Methods
    
    func isUserLoggedIn() -> Bool {
        return loadTokenFromKeychain() != nil || serverData?.user.id != nil
    }
    
    func logout() {
        deleteTokenFromKeychain()
        self.token = nil
        socket?.disconnect()
        self.serverData = nil
    }
    
    // MARK: - Socket Methods
    
    func connectSocket() {
        guard let token = self.token else {
            print("No token available")
            return
        }
        
        socketManager = SocketManager(socketURL: URL(string: baseURL)!, config: [
            .log(true),
            .compress,
            .connectParams(["token": token])
        ])
        socket = socketManager?.defaultSocket
        
        // Handle socket connection events
        socket?.on(clientEvent: .connect) { data, ack in
            print("Socket connected")
        }
        
        socket?.on(clientEvent: .disconnect) { data, ack in
            print("Socket disconnected")
        }
        
        socket?.on(clientEvent: .error) { [weak self] data, ack in
            print("Socket error: \(data)")
            self?.handleConnectionError(data)
        }
        
        socket?.on(clientEvent: .reconnect) { data, ack in
            print("Socket reconnecting")
        }
        
        // Handle custom events
        socket?.on("update") { [weak self] data, ack in
            guard let self = self,
                  let infoData = data.first as? [String: Any],
                  let syncResponse = infoData["sync"] as? [String: Any]
            else{
                print("Invalid data received")
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: syncResponse)
                let decoder = JSONDecoder()
                let response = try decoder.decode(FullSyncResponse.self, from: jsonData)
                DispatchQueue.main.async {
                    self.serverData = response
                    print(self.serverData)
                }
                
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }
        
        socket?.on("syncedPuffIds") { [weak self] data, ack in
            guard let self = self,
                  let infoData = data.first as? [String: Any],
                  let syncedPuffIds = infoData["syncedPuffIds"] as? [String]
            else {
                print("Invalid error data received")
                return
            }
            do{
                self.lastSyncedPuffs = syncedPuffIds
            }
        }
        
        socket?.on("error") { [weak self] data, ack in
            guard let self = self,
                  let infoData = data.first as? [String: Any],
                  let errorMessage = infoData["message"] as? String
            else {
                print("Invalid error data received")
                return
            }
            self.handleServerError(errorMessage)
        }
        
        socket?.on("puffCount") { [weak self] data, ack in
            guard let self = self,
                  let infoData = data.first as? [String: Any],
                  let serverPuffCount = infoData["puffCount"] as? Int
            else {
                print("Invalid error data received")
                return
            }
            do{
                self.serverPuffCount = serverPuffCount
            }
        }
        
        
        socket?.connect()
    }
    
    private func handleServerError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            if message.lowercased().contains("authentication") || message.lowercased().contains("unauthorized") || message.lowercased().contains("user does not exist"){
                self?.logout()
                self?.isErrorDisplayed = true
                self?.errorMessage = "Authentication failed. Please log in again."
            } else {
                self?.isErrorDisplayed = true
                self?.errorMessage = "Server Error: \(message)"
            }
        }
    }
    
    
    private func handleConnectionError(_ data: [Any]) {
        DispatchQueue.main.async { [weak self] in
            if let error = data.first as? String, error.contains("Authentication error") {
                self?.logout()
                self?.isErrorDisplayed = true
                self?.errorMessage = "Authentication failed. Please log in again."
            } else {
                self?.isErrorDisplayed = true
                self?.errorMessage = "Failed to connect. Please check your internet connection and try again."
            }
        }
    }
    
    private func handleDisconnect() {
        DispatchQueue.main.async { [weak self] in
            self?.isErrorDisplayed = true
            self?.errorMessage = "Disconnected from server. Please check your internet connection."
        }
    }
    
    
    func sendEvent(event: String, withData data: [String: Any]? = nil) {
        guard let socket = socket, socket.status == .connected else {
            print("Socket is not connected. Event not sent:", event)
            return
        }
        
        if let data = data {
            socket.emit(event, data)
        } else {
            socket.emit(event)
        }
    }
}

struct FullSyncResponse: Codable {
    var user: User
    let friends: [Friend]
    let sentFriendRequests: [FriendRequest]
    let receivedFriendRequests: [FriendRequest]
}

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
}

struct Friend: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let puffsummary: PuffSummary
}

struct FriendRequest: Codable, Identifiable {
    let id: String
    let status: String
    let receiver: User?
    let sender: User?
    
    enum CodingKeys: String, CodingKey {
        case id, status
        case receiver = "receiver"
        case sender = "sender"
    }
}



struct PuffSummary: Codable, Identifiable {
    let id: UUID
    let puffsToday: Int
    let averagePuffsPerDay: String
    let changePercentage: String
    let pufflessDayStreak: Int
    
    enum CodingKeys: String, CodingKey {
        case puffsToday, averagePuffsPerDay, changePercentage, pufflessDayStreak
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        puffsToday = try container.decode(Int.self, forKey: .puffsToday)
        averagePuffsPerDay = try container.decode(String.self, forKey: .averagePuffsPerDay)
        changePercentage = try container.decode(String.self, forKey: .changePercentage)
        pufflessDayStreak = try container.decode(Int.self, forKey: .pufflessDayStreak)
    }
}
