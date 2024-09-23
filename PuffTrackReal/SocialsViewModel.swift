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
    
    @Published var serverData: FullSyncResponse?
    private let baseURL = "http://localhost:3000"
    private var token: String?
    
    private let keychainServiceName = "com.yourapp.identifier" // Replace with your app's bundle identifier
    private let tokenKey = "authToken"
    
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
    
    func register(name: String, email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "\(baseURL)/register"
        let body: [String: Any] = ["name": name, "email": email, "password": password]
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            // Handle errors
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0)))
                return
            }
            
            // Parse JSON response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    DispatchQueue.main.async {
                        self?.token = token
                        self?.saveTokenToKeychain(token)
                        self?.connectSocket()
                    }
                    completion(.success(token))
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: 0)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func login(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "\(baseURL)/login"
        let body: [String: Any] = ["email": email, "password": password]
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            // Handle errors
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0)))
                return
            }
            
            // Parse JSON response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let token = json["token"] as? String {
                    DispatchQueue.main.async {
                        self?.token = token
                        self?.saveTokenToKeychain(token)
                        self?.connectSocket()
                    }
                    completion(.success(token))
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: 0)))
                }
            } catch {
                completion(.failure(error))
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
        return loadTokenFromKeychain() != nil
    }
    
    func logout() {
        deleteTokenFromKeychain()
        self.token = nil
        socket?.disconnect()
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
            self?.handleSocketError(data)
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
        
        socket?.connect()
    }
    
    private func handleSocketError(_ data: [Any]) {
        // Check if the error is due to authentication failure
        logout()
    }
    
    func sendEvent(event: String, withData data: [String: Any]? = nil) {
        if let data = data {
            socket?.emit(event, data)
        } else {
            socket?.emit(event)
        }
    }
}

struct FullSyncResponse: Codable {
    let user: User
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
