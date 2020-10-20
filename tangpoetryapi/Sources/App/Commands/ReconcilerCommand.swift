import Vapor
import Fluent

struct ReconcilerCommand: Command {
    
    let help = "This command load resource json file"
    
    struct Signature: CommandSignature {
        /*
         swift run Run reconciler poet.tang.0.json
         
         $ docker cp ./Resources tangpoetryapi_app_1:/app
         $ docker exec -it tangpoetryapi_app_1 ./Run reconciler poet.tang.0.json
         
         # name:poet.tang.0.json folder:Resources/json show:false
         */
        @Argument(name: "name", help: "Resource file name")
        var fileName: String
        
        /*
         swift run Run reconciler poet.tang.0.json -f Resources/json
         
         # name:poet.tang.0.json folder:Resources/json show:false
         */
        @Option(name: "folder", short: "f", help: "Greeting used")
        var folder: String?
        
        /*
         swift run Run reconciler poet.tang.0.json -f Resources/json -s
         
         # name:poet.tang.0.json folder:Resources/json show:true
         # jsonPath:file:///Users/finervine/Desktop/SwiftWeb/tangpoetry/tangpoetry/Resources/json/poet.tang.0.json
         */
        @Flag(name: "show", short: "s", help: "show real path")
        var showPath: Bool
    }
    
    func run(using context: CommandContext, signature: Signature) throws {
        let name = signature.fileName
        let folder: String = signature.folder ?? "Resources/json"
        let show = signature.showPath
        
        //        let data = try fromFile(name, folder: folder, showPath: show)
        let poets = try loadFromFile(fromFile(name, folder: folder, showPath: show), database: context.application.db)
        try poets.create(on: context.application.db).wait()
    }
    
    func fromFile(_ fileName: String,folder: String = "Resources/json", showPath: Bool = false) throws -> Data {
        let directory = DirectoryConfiguration.detect()
        let fileURL = URL(fileURLWithPath: directory.workingDirectory)
            .appendingPathComponent(folder, isDirectory: true)
            .appendingPathComponent(fileName, isDirectory: false)
        if showPath {
            print("jsonPath:\(fileURL.absoluteString)")
        }
        return try Data(contentsOf: fileURL, options: Data.ReadingOptions.mappedIfSafe)
    }
    
    func loadFromFile(_ poetryTangData: Data, database: Database) throws -> [PoetTang] {
        struct PoetryTangDecoderObject: Decodable {
            let id: UUID
            let title: String
            let author: String
            let paragraphs: [String]
        }
        
        let decoder = JSONDecoder()
        let decodedPoetryTangs = try decoder.decode([PoetryTangDecoderObject].self,from: poetryTangData)
        var poetTangs: [PoetTang] = []
        for service in decodedPoetryTangs {
            let author = try PoetTangAuthor
                .query(on: database)
                .filter(\.$name == service.author)
                .first()
                .flatMap { (author) -> EventLoopFuture<PoetTangAuthor> in
                    if let author = author {
                        return database.eventLoop.future(author)
                    } else {
                        let newAuthor = PoetTangAuthor(name: service.author, desc: "未知作者")
                        return newAuthor.save(on: database).map { newAuthor }
                    }
            }.wait()
            
            let poet = try PoetTang.init(id: service.id, title: service.title.simplified, authorName: service.author.simplified, content: service.paragraphs.joined(separator: "\n").simplified, authorID: author.requireID())
            poetTangs.append(poet)
        }
        return poetTangs
    }
}
