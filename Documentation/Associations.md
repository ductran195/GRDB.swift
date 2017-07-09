GRDB Associations
=================

> [**:fire: EXPERIMENTAL**](http://github.com/groue/GRDB.swift#what-are-experimental-features): GRDB associations are young, and not stabilized yet. To help them becoming stable, [your feedback](https://github.com/groue/GRDB.swift/issues) is greatly appreciated.

**An association is a connection between two [Record](http://github.com/groue/GRDB.swift#records) types.** It helps your code perform common operations in an easier way.

For example, consider an application that defines two record types for authors and books. Each author can have many books:

```swift
class Author: Record { ... }
class Book: Record { ... }
```

Without associations, loading all authors with all their books would look like:

```swift
let allAuthorsWithTheirBooks = try dbQueue.inDatabase { db in
    let authors = try Author.fetchAll(db)
    return try authors.map { author in
        let books = try Book
            .filter(Book.Columns.authorId == author.id)
            .fetchAll(db)
        return (author, books)
    }
}
```

With associations, this code can be streamlined. Associations are declared in the record types:

```swift
class Author: Record {
    static let books = hasMany(Book.self)
    ...
}

class Book: Record {
    static let author = belongsTo(Author.self)
    ...
}
```

After associations have been declared, loading all authors with their books is easier:

```swift
let allAuthorsWithTheirBooks = try dbQueue.inDatabase { db in
    return Author.including(Author.books).fetchAll(db)
}
```

Associations bring simpler APIs for a lot more operations. We'll introduce below the various kinds of associations, and provide the reference to their methods and options.


## The Types of Associations

GRDB handles eight types of associations:

- [BelongsTo](#belongsto)
- [BelongsToOptional](#belongstooptional)
- [HasMany](#hasmany)
- [HasManyThrough](#hasmanythrough)
- [HasOne](#hasone)
- [HasOneOptional](#hasoneoptional)
- [HasOneThrough](#hasonethrough)
- [HasOneOptionalThrough](#hasoneoptionalthrough)

An association declares a link from a record type to another, as in "one book *belongs to* its author". It instructs GRDB to use the primary and foreign keys declared in the database as support for Swift methods.

Each one of the eight types of associations is appropriate for a particular database situation.


### BelongsTo

The *BelongsTo* association sets up a one-to-one connection from a record type to another record type, such as each instance of the declaring record "belongs to" an instance of the other record.

For example, if your application includes authors and books, and each book is assigned exactly one author, you'd declare the association this way:

```swift
class Author: Record {
    ...
}

class Book: Record {
    static let author = belongsTo(Author.self)
    ...
}
```

A book **belongs to** its author:

![BelongsToSchema](https://cdn.rawgit.com/groue/GRDB.swift/Graph/Documentation/Images/BelongsToSchema.svg)

The matching [migration](http://github.com/groue/GRDB.swift#migrations) would look like:

```swift
migrator.registerMigration("BooksAndAuthors") { db in
    try db.create(table: "authors") { t in
        t.column("id", .integer).primaryKey()
        t.column("name", .text)
    }
    try db.create(table: "books") { t in
        t.column("id", .integer).primaryKey()
        t.column("authorId", .integer)
            .notNull()
            .indexed()
            .references("authors", onDelete: .cascade)
        t.column("title", .text)
    }
}
```

> :point_up: **Note**: The BelongsTo association wants a non-optional associated record. In our example, each book must have its author.


### BelongsToOptional

The *BelongsToOptional* association also sets up a one-to-one connection from a record type to another record type, such as each instance of the declaring record "belongs to" an instance of the other record. Unlike the *BelongsTo* association, the associated record is optional.

For example, if your application includes authors and books, and each book is assigned zero or one author, not more, you'd declare the association this way:

```swift
class Author: Record {
    ...
}

class Book: Record {
    static let author = belongsTo(optional: Author.self)
    ...
}
```

A book **belongs to** its **optional** author:

![BelongsToSchema](https://cdn.rawgit.com/groue/GRDB.swift/Graph/Documentation/Images/BelongsToSchema.svg)

The matching [migration](http://github.com/groue/GRDB.swift#migrations) would look like:

```swift
migrator.registerMigration("BooksAndAuthors") { db in
    try db.create(table: "authors") { t in
        t.column("id", .integer).primaryKey()
        t.column("name", .text)
    }
    try db.create(table: "books") { t in
        t.column("id", .integer).primaryKey()
        t.column("authorId", .integer)
            .indexed()
            .references("authors", onDelete: .cascade)
        t.column("title", .text)
    }
}
```


### HasMany

The *HasMany* association indicates a one-to-many connection between two record types, such as each instance of the declaring record "has many" instances of the other record. You'll often find this association on the other side of a *BelongsTo* or *BelongsToOptional* association.

For example, if your application includes authors and books, and each author is assigned zero or more books, you'd declare the association this way:

```swift
class Author: Record {
    static let books = hasMany(Book.self)
}

class Book: Record {
    ...
}
```

An author **has many** books:

![HasManySchema](https://cdn.rawgit.com/groue/GRDB.swift/Graph/Documentation/Images/HasManySchema.svg)

The matching [migration](http://github.com/groue/GRDB.swift#migrations) would look like:

```swift
migrator.registerMigration("BooksAndAuthors") { db in
    try db.create(table: "authors") { t in
        t.column("id", .integer).primaryKey()
        t.column("name", .text)
    }
    try db.create(table: "books") { t in
        t.column("id", .integer).primaryKey()
        t.column("authorId", .integer)
            .indexed()
            .references("authors", onDelete: .cascade)
        t.column("title", .text)
    }
}
```