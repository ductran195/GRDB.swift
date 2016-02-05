//: To run this playground, select and build the GRDBOSX scheme.
//:
//: Record
//: ======
//:
//: This playground is a demo of the Record class, the type that provides fetching methods, persistence methods, and change tracking.

import GRDB


//: ## Setup
//:
//: First open an in-memory database, with a trace function that prints all SQL statements.

var configuration = Configuration()
configuration.trace = { print($0) }
let dbQueue = DatabaseQueue(configuration: configuration)

//: Create a database table which stores persons.

try dbQueue.inDatabase { db in
    try db.execute(
        "CREATE TABLE persons (" +
            "id INTEGER PRIMARY KEY, " +
            "firstName TEXT, " +
            "lastName TEXT" +
        ")")
}


//: ## Subclassing Record
//:
//: The Person class is a subclass of Record, with regular properties, and a regular initializer:

class Person : Record {
    var id: Int64?
    var firstName: String?
    var lastName: String?
    
    var fullName: String {
        return [firstName, lastName].flatMap { $0 }.joinWithSeparator(" ")
    }
    
    init(firstName: String?, lastName: String?) {
        self.id = nil
        self.firstName = firstName
        self.lastName = lastName
        super.init()
    }
    
    
//: Subclasses of Record have to override the methods that define how they interact with the database.
//:
//: 1. The table name:
    
    override class func databaseTableName() -> String {
        return "persons"
    }
    
//: 2. How to build a Person from a database row:
    
    required init(_ row: Row) {
        id = row.value(named: "id")
        firstName = row.value(named: "firstName")
        lastName = row.value(named: "lastName")
        super.init(row)
    }
    
//: 3. The dictionary of values that are stored in the database:
    
    override var persistentDictionary: [String: DatabaseValueConvertible?] {
        return ["id": id, "firstName": firstName, "lastName": lastName]
    }
    
//: 4. When relevant, update the person's id after a database row has been inserted:
    
    override func didInsertWithRowID(rowID: Int64, forColumn column: String?) {
        id = rowID
    }
}


//: ## Insert Records
//:
//: Persons are regular objects, that you can freely create:

let arthur = Person(firstName: "Arthur", lastName: "Miller")
let barbra = Person(firstName: "Barbra", lastName: "Streisand")
let cinderella = Person(firstName: "Cinderella", lastName: nil)

//: They are not stored in the database yet. Insert them:

try dbQueue.inDatabase { db in
    try arthur.insert(db)
    try barbra.insert(db)
    try cinderella.insert(db)
}


//: ## Fetching Records

dbQueue.inDatabase { db in
//: Fetch records from the database:
    let allPersons = Person.fetchAll(db)
    
//: Fetch record by primary key:
    let person = Person.fetchOne(db, key: arthur.id)!
    person.fullName

//: Fetch persons with an SQL query:
    let millers = Person.fetchAll(db, "SELECT * FROM persons WHERE lastName = ?", arguments: ["Miller"])
    millers.first!.fullName
}


//: ## The Query Interface
//:
//: The query interface lets you write Swift instead of SQL.
//:
//: First define the colums you want to use in the query interface

struct Col {
    static let firstName = SQLColumn("firstName")
    static let lastName = SQLColumn("lastName")
}

//: Use columns to filter or order fetched records:

dbQueue.inDatabase { db in
//: Use columns for sorting:
    let personsSortedByName = Person.order(Col.firstName, Col.lastName).fetchAll(db)
    
//: Use columns for filtering:
    let millers = Person.filter(Col.lastName == "Miller").fetchAll(db)
}
