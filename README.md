## Blockchain by Swift ##
### A simple implementation of blockchain in Swift ###

### Requirements
* [Swift 4](https://swift.org/download/)

Dependencies
1. [Kitura](http://www.kitura.io/) for processing HTTP reqeuests .
2. [SwiftyRequest](https://github.com/IBM-Swift/SwiftyRequest) for making HTTP requests. (When we are working with more than one Nodes)
3. [CryptoSwift](https://cryptoswift.io) for hashing


### Run
#### Xcode
You can run your project in Xcode by opening the `swift blockchain.xcproject` file that has been generated for you. Select the target  which matches your project name in the upper left hand corner of the window, choose 'My Mac' and click the play button. Your server should now be accessible by going to `localhost:5000` in your browser.

#### Command-line
Run `swift build` in the project's directory, then run `/.build/debug/swift blockchain` to start the Kitura server. Your server should now be accessible by going to `localhost:5000` in your browser.
