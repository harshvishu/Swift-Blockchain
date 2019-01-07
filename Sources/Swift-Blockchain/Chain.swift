//
//  File.swift
//  Swift-Blockchain
//
//  Created by harsh vishwakarma on 08/01/19.
//

import Foundation

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

protocol Chain: class {
    // MARK: - Properties
    var chain: [Block] {get}
    var current_transactions: [Transaction] {get}
    var nodes: Set<String> {get}
    
    
    // MARK: - Methods
    
    /**
     # Creates a new block and adds it to the chain
     
     - Parameter proof: <int> The proof given by the Proof of Work algorithm
     - Parameter previous_hash: (Optional) <str> Hash of previous Block
     - returns: _dict_ New Block
     
     */
    func newBlock(previous_hash: String?, proof: Int64) -> Block
    
    /**
     Creates a new transaction to go into the next mined Block
     
     - Parameter sender: Address of the Sender
     - Parameter recipient: Address of the Recipient
     - Parameter amount: Amount
     - returns: The index of the Block that will hold this transaction
     */
    func newTransaction(sender: String, recipient: String, amount: Int64) -> Int64
    
    /**
     Creates a SHA-256 hash of a Block
     
     - Parameter block: <dict> Block
     - returns: String
     
     */
    func hash(block: Block) -> String
    
    /**
     Simple Proof of Work Algorithm:
     
     - Find a number p' such that hash(pp') contains leading 4 zeroes, where p is the previous p'
     - p is the previous proof, and p' is the new proof
     - Parameter: last_proof: Int64
     - returns: Int64
     """
     */
    func proofOfWork(last_proof: Int64) -> Int64
    
    /**
     Validates the Proof: Does hash(last_proof, proof) contain 4 leading zeroes?
     
     - Parameter last_proof: <int> Previous Proof
     - Parameter proof: <int> Current Proof
     - returns: True if correct, False if not.
     */
    func validProof(last_proof: Int64, proof: Int64) -> Bool
    
    
    /**
     Add a new node to the list of nodes
     
     - Parameter address: Address of node. Eg. 'http://192.168.0.5:5000'
     */
    func registerNode(address: String) -> Bool
    
    /**
     Determine if a given blockchain is valid
     
     - Parameter chain: A blockchain
     - returns: True if valid, False if not
     */
    func validChain(_ chain: [Block]) -> Bool
    
    /**
     This is our Consensus Algorithm, it resolves conflicts
     by replacing our chain with the longest one in the network.
     
     - returns: True if our chain was replaced, False if not
     */
    func resolveConflicts() -> Bool 
}
