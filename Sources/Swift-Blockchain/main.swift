import Kitura
import Foundation
import CryptoSwift
import KituraNet
import SwiftyRequest

struct Block: Codable {
    var index: Int64
    var timestamp: Date
    var transactions: [Transaction]
    var proof: Int64
    var previous_hash: String
}

struct Transaction: Codable {
    var sender: String
    var recipient: String
    var amount: Int64
}

class Blockchain {
    // MARK: - Properties
    var chain: [Block]
    var current_transactions: [Transaction]
    var nodes: Set<String>
    
    // MARK: - Initializers
    init() {
        chain = []
        current_transactions = []
        nodes = Set()
        
        // Create the genesis block
        self.newBlock(previous_hash: "1", proof: 100)
    }
    
    // MARK: - Methods
    
    /**
     # Creates a new block and adds it to the chain
     
     - Parameter proof: <int> The proof given by the Proof of Work algorithm
     - Parameter previous_hash: (Optional) <str> Hash of previous Block
     - returns: _dict_ New Block
     
     */
    @discardableResult
    func newBlock(previous_hash: String?, proof: Int64) -> Block {
        let block = Block(index: Int64(self.chain.count + 1),
                          timestamp: Date(),
                          transactions: self.current_transactions,
                          proof: proof,
                          previous_hash: previous_hash ?? self.hash(block: self.last_block)
        )
        
        // Reset the current list of transactions
        self.current_transactions = []
        self.chain.append(block)
        
        return block
    }
    
    func newTransaction(sender: String, recipient: String, amount: Int64) -> Int64 {
        let transaction = Transaction(sender: sender, recipient: recipient, amount: amount)
        self.current_transactions.append(transaction)
        
        return self.last_block.index + 1
    }
    
    var last_block: Block {
        return self.chain[self.chain.count - 1]
    }
    
    /**
     Creates a SHA-256 hash of a Block
     
     - Parameter block: <dict> Block
     - returns: String
     
     */
    func hash(block: Block) -> String {
        let encoder = JSONEncoder()
        // We must make sure that the Dictionary is Ordered, or we'll have inconsistent hashes
        if #available(OSX 10.13, *) {
            encoder.outputFormatting = .sortedKeys
        }
        
        let str = try! String(data: encoder.encode(block), encoding: .utf8)!
        return str.sha256()
    }
    
    /**
     Simple Proof of Work Algorithm:
     
     - Find a number p' such that hash(pp') contains leading 4 zeroes, where p is the previous p'
     - p is the previous proof, and p' is the new proof
     - Parameter: last_proof: Int64
     - returns: Int64
     """
     */
    func proofOfWork(last_proof: Int64) -> Int64 {
        var proof: Int64 = 0
        while !self.validProof(last_proof: last_proof, proof: proof) {
            proof += 1
        }
        
        return proof
    }
    
    /**
     Validates the Proof: Does hash(last_proof, proof) contain 4 leading zeroes?
     
     - Parameter last_proof: <int> Previous Proof
     - Parameter proof: <int> Current Proof
     - returns: True if correct, False if not.
     */
    func validProof(last_proof: Int64, proof: Int64) -> Bool {
        let guess = "\(last_proof)\(proof)"
        let guess_hash = guess.sha256()
        return guess_hash.suffix(4) == "0000"
    }
    
    // Generate a globally unique address for this node
    var node_identifier: String {
        return ProcessInfo().globallyUniqueString.replacingOccurrences(of: "-", with: "")
    }
    
    /**
     Add a new node to the list of nodes
     
     - Parameter address: Address of node. Eg. 'http://192.168.0.5:5000'
     */
    func registerNode(address: String) -> Bool {
        let options = ClientRequest.parse(address)
        for option in options {
            if case let ClientRequest.Options.hostname(host) = option, !host.isEmpty {
                self.nodes.insert(host)
                return true
            }
        }
        print("Invalid URL")
        return false
    }
    
    /**
     Determine if a given blockchain is valid
     
     - Parameter chain: A blockchain
     - returns: True if valid, False if not
     */
    func validChain(_ chain: [Block]) -> Bool {
        var last_block = chain[0]
        var current_index = 1
        
        while current_index < chain.count {
            let block = chain[current_index]
            print("\(last_block)")
            print("\(block)")
            print("\n----------\n")
            // Check the hash of the block is correct
            let last_block_hash = self.hash(block: last_block)
            if block.previous_hash != last_block_hash {
                return false
            }
            // Check that the Proof of Work is correct
            if !self.validProof(last_proof: last_block.proof, proof: block.proof) {
                return false
            }
            
            last_block = block
            current_index += 1
        }
        return true
    }
    
    /**
     This is our Consensus Algorithm, it resolves conflicts
     by replacing our chain with the longest one in the network.
     
     - returns: True if our chain was replaced, False if not
     */
    func resolveConflicts() -> Bool {
        let neighbours = self.nodes
        var new_chain: [Block]?
        
        // We're only looking for chains longer than ours
        var max_length = self.chain.count
        
        // Grab and verify the chains from all the nodes in our network
        for node in neighbours {
            let semaphore = DispatchSemaphore(value: 0)
            
            struct ResponseData: Decodable {
                let chain: [Block]
                let length: Int
            }
            
            let request = RestRequest(method: .get, url: "http://\(node):5000/chain")
            request.responseObject { (response: RestResponse<ResponseData>) in
                switch response.result {
                case .success(let response_data):
                    let length = response_data.length
                    let chain = response_data.chain
                    
                    if length > max_length && self.validChain(chain) {
                        max_length = length
                        new_chain = chain
                    }
                case .failure(let error):
                    print(error)
                }
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .distantFuture)
        }
        
        // Replace our chain if we discovered a new, valid chain longer than ours
        if let new_chain = new_chain {
            self.chain = new_chain
            return true
        }

        return false
    }
    
}

let blockchain = Blockchain()


// Create a new router
let router = Router()
router.all(middleware: BodyParser())

// Handle HTTP GET requests to /
router.get("/") {
    request, response, next in
    defer {next()}
    response.status(.OK)
    response.send("Welcome to Swift Blockchain")
}

router.get("/mine") {
    request, response, next in
    defer {next()}
    
    let last_block = blockchain.last_block
    let last_proof = last_block.proof
    let proof = blockchain.proofOfWork(last_proof: last_proof)
    
    // We must receive a reward for finding the proof.
    // The sender is "0" to signify that this node has mined a new coin.
    blockchain.newTransaction(sender: "0", recipient: blockchain.node_identifier, amount: 1)
    
    // Forge the new Block by adding it to the chain
    let previous_hash = blockchain.hash(block: last_block)
    let block = blockchain.newBlock(previous_hash: previous_hash, proof: proof)
    
    struct ResponseData: Encodable {
        let message: String
        let index: Int64
        let transactions: [Transaction]
        let proof: Int64
        let previous_hash: String
    }
    let response_data = ResponseData(message: "New Block Foreged",
                                     index: block.index,
                                     transactions: block.transactions,
                                     proof: proof,
                                     previous_hash: previous_hash)
    response.status(.OK)
    response.send(response_data)
}

router.post("/transactions/new") {
    request, response, next in
    defer {next()}
    
    guard let body = request.body?.asJSON,
        let sender = body["sender"] as? String,
        let recipient = body["recipient"] as? String,
        let amount = body["amount"] as? Int64
        else {
            response.status(.badRequest)
            response.send("Missing values")
            return
    }
    let index = blockchain.newTransaction(sender: sender, recipient: recipient, amount: amount)
    struct ResponseData: Encodable {
        let message: String
    }
    let response_data = ResponseData(message: "Transaction will be added to Block \(index)")
    response.status(.created)
    response.send(response_data)
}


router.get("/chain") {
    request, response, next in
    defer {next()}
    struct ResponseData: Encodable {
        let chain: [Block]
        let length: Int
    }
    
    let response_data = ResponseData(chain: blockchain.chain, length: blockchain.chain.count)
    response.status(.OK)
    response.send(response_data)
}

router.post("/nodes/register") {
    request, response, next in
    defer {next()}
    
    guard let body = request.body?.asJSON,
        let nodes = body["nodes"] as? [String]
        else {
            response.status(.badRequest)
            response.send("Error: Please supply a valid list of nodes")
            return
    }
    
    for node in nodes {
        _ = blockchain.registerNode(address: node)
    }
    
    struct ResponseData: Encodable {
        let message: String
        let total_nodes: [String]
    }
    
    let response_data = ResponseData(message: "New nodes have been added", total_nodes: Array(blockchain.nodes))
    response.status(.created)
    response.send(response_data)
}

router.get("/nodes/resolve") {
    request, response, next in
    defer {next()}
    
    let replaced = blockchain.resolveConflicts()
    response.status(.OK)
    if replaced {
        struct ResponseData: Encodable {
            let message: String
            let new_chain: [Block]
        }
        let response_data = ResponseData(message: "Our chain was replaced", new_chain: blockchain.chain)
        response.send(response_data)
    } else {
        struct ResponseData: Encodable {
            let message: String
            let chain: [Block]
        }
        let response_data = ResponseData(message: "Our chain is authoritative", chain: blockchain.chain)
        response.send(response_data)
    }
}

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 5000, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()

