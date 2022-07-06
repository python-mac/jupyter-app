import Foundation

enum JupyterError: Error {
    case notFound
    case wrongFile(String)
    
    var description: String {
        switch self {
            case .notFound:
            return "Failed to launch jupyter"
            
            case let .wrongFile(filepath):
            return "Incorrect file provided: '\(filepath)'"
        }
    }
}

class Jupyter {
    let process: Process?

    let port: String
    let token: String
    
    static let root: String = {
        
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        
        task.launchPath = "/bin/zsh"
        task.arguments = ["-l", Bundle.main.resourceURL!.path + "/get-root-dir.sh"]
        
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        if let output = String(data: data, encoding: .utf8) {
            
            print("output", output, "end output", separator: ":", terminator: "\n")
            
            if output != "" && output != "\n" {
                // remove last character (newline)
                // I love swift strings btw
                return String(output[output.startIndex..<output.index(before: output.endIndex)])
            }
        }
        
        return FileManager.default.homeDirectoryForCurrentUser.path
    }()
    
    func url(for path: String = "") -> String {
        
        var filePath = path
        
        // remove root directory from path
        if filePath.starts(with: Jupyter.root) {
            filePath = filePath.get(after: Jupyter.root)
        }
        
        let encodedPath = filePath.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        return "http://localhost:\(self.port)/notebooks\(encodedPath)?token=\(self.token)"
    }
    
    init() throws {
        // we need to launch jupyter kernel ourselves
        let (process, filePath) = try Jupyter.launchProcess()
        self.process = process
        
        let url = try Jupyter.getURL(from: filePath)
        (self.port, self.token) = Jupyter.parseURL(url)
    }
    
    init(fromURL url: String) {
        // if it's from the commandline, we don't want to open jupyter ourselves
        self.process = nil
        
        (self.port, self.token) = Jupyter.parseURL(url)
    }
    
    deinit {
        if let process = self.process {
            // not killing it potentially gives it time to save files
            // so we are simulating ^C twice
            
            process.interrupt()
            usleep(5000) // too fast won't be registered
            process.interrupt()
        }
    }
    
    static func launchProcess() throws -> (Process, String) {
        // try to launch jupyter and get input file
        
        let task = Process()
        
        task.launchPath = "/bin/zsh"
        task.currentDirectoryPath = self.root
        task.arguments = ["-l", Bundle.main.resourceURL!.path + "/launch-jupyter.sh"]
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe

        do { try task.run() }
        catch { throw JupyterError.notFound }
        
        var filename = ""
        while true {
            if let out = try? outputPipe.fileHandleForReading.read(upToCount: 1) {
                filename += String(decoding: out, as: UTF8.self)
                
                if filename.hasSuffix(".html") { break }
                
            } else { break }
        }
        
        return (jupyter: task, filename: filename)
    }
    
    static func getURL(from file: String) throws -> String {
        // from jupyter we obtain an absolute path to temporary file
        // were the link is stored. we need the link to be able to obtain
        // the token and the port
        
        // note: if the format of the file ever changes, we are in trouble
    
        let path = file.get(after: "file://").removingPercentEncoding!
        
        do {
            let data =  try String(contentsOfFile: path)
            let urlBase = "http://localhost:"
            
            let url = URL(string: urlBase + data.get(after: urlBase, until: "\""))!
            return url.absoluteString
            
        } catch {
            throw JupyterError.wrongFile(path)
        }
    }

    static func parseURL(_ url: String) -> (String, String) {
        
        let port = url.get(after: "http://localhost:", until: "/")
        let token = url.get(after: "?token=")
        
        return (port, token)
    }
}
