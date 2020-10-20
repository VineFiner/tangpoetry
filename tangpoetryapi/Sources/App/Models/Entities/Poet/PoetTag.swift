//
//  Tag.swift
//  App
//
//  Created by Finer  Vine on 2020/7/4.
//
import Fluent
import Vapor

final class PoetTag: Model, Content {
    // Name of the table or collection.
    static let schema: String = "poettags"

    // Unique identifier for this Tag.
    @ID(key: .id)
    var id: UUID?

    // When this Planet was created.
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    // Stores an ISO 8601 formatted timestamp representing
    // when this model was last updated.
    @Timestamp(key: "updated_at", on: .update, format: .iso8601)
    var updatedAt: Date?
    
    // When this Planet was deleted.
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
    
    // The Tag's name.
    @Field(key: "name")
    var name: String
    
    /*
     through: The pivot model's type.
     from: Key path from the pivot to the parent relation referencing the root model.
     to: Key path from the pivot to the parent relation referencing the related model.
     */
    @Siblings(through: PoetTangTag.self, from: \.$tag, to: \.$poetTang)
    public var poets: [PoetTang]
    
    // Creates a new, empty Tag.
    init() {}

    // Creates a new Tag with all properties set.
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
