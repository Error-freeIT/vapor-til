import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "acronyms")
        
        // Get all acronyms.
        acronymsRoutes.get(use: getAllHandler)
        // Add new acronym. (/api/acronyms)
        acronymsRoutes.post(Acronym.self, use: createHandler)
        // Get acronym with ID equal to URL parameter.
        acronymsRoutes.get(Acronym.parameter, use: getHandler)
        // Update acronym with ID equal to URL parameter.
        acronymsRoutes.put(Acronym.parameter, use: updateHandler)
        // Delete acronym with ID equal to URL parameter.
        acronymsRoutes.delete(Acronym.parameter, use: deleteHandler)
        // Get acronym with short/long value equal to search parameter.
        acronymsRoutes.get("search", use: searchHandler)
        // Get first acronym in database.
        acronymsRoutes.get("first", use: getFirstHandler)
        // Get all acronyms sorted alphabetically.
        acronymsRoutes.get("sorted", use: sortedHandler)
        // Get user info for acronym ID. (/api/acronyms/<ACRONYM_ID>/user)
        acronymsRoutes.get(Acronym.parameter, "user", use: getUserHandler)
        // Creates a sibling relationshop between an acronym and a category. (/api/acronyms/<ACRONYM_ID>/categories/<CATEGORY_ID>)
        acronymsRoutes.post(Acronym.parameter, "categories", Category.parameter, use: addCategoriesHandler)
        // Return categories belonging to a acronym. (/api/acronyms/<ACRONYM_ID>/categories)
        acronymsRoutes.get(Acronym.parameter, "categories", use: getCategoriesHandler)
        // Delete a sibling relationship between an acronym and a category. (/api/acronyms/<ACRONYM_ID>/categories/<CATEGORY_ID>)
        acronymsRoutes.delete(Acronym.parameter, "categories", Category.parameter, use: removeCategoriesHandler)
    }

    // Get all acronums.
    func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
    
    // Create new entry.
    func createHandler(_ req: Request, acronym: Acronym) throws -> Future<Acronym> {
        //return try req.content.decode(Acronym.self).flatMap(to: Acronym.self) { acronym in
            return acronym.save(on: req)
        //}
    }
    
    // Get acronym with ID equal to URL parameter.
    func getHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.parameters.next(Acronym.self)
    }
    
    // Update acronym with ID equal to URL parameter.
    func updateHandler(_ req: Request) throws -> Future<Acronym> {
        return try flatMap(to: Acronym.self, req.parameters.next(Acronym.self), req.content.decode(Acronym.self)) { acronym, updatedAcronym in
            acronym.short = updatedAcronym.short
            acronym.long = updatedAcronym.long
            acronym.userID = updatedAcronym.userID
            return acronym.save(on: req)
        }
    }
    
    // Delete acronym with ID equal to URL parameter.
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Acronym.self).delete(on: req).transform(to: HTTPStatus.noContent)
    }
    
    // Get acronym with short/long value equal to URL search parameter.
    func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
                throw Abort(.badRequest)
        }
        return Acronym.query(on: req).group(.or) { or in
            or.filter(\.short == searchTerm)
            or.filter(\.long == searchTerm)
        }.all()
    }
    
    // Get first acronym in database.
    func getFirstHandler(_ req: Request) throws -> Future<Acronym> {
        return Acronym.query(on: req).first().map(to: Acronym.self) { acronym in
                guard let acronym = acronym else {
                    throw Abort(.notFound)
                }
                return acronym
        }
    }
    
    // Get all acronyms sorted alphabetically.
    func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).sort(\.short, .ascending).all()
    }
    
    // Get user info for acronym ID. (/api/acronyms/<ACRONYM_ID>/user)
    func getUserHandler(_ req: Request) throws -> Future<User> {
        return try req.parameters.next(Acronym.self).flatMap(to: User.self) { acronym in
            acronym.user.get(on: req)
        }
    }
    
    // Creates a sibling relationshop between an acronym and a category. (/api/acronyms/<ACRONYM_ID>/categories/<CATEGORY_ID>)
    func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self, req.parameters.next(Acronym.self), req.parameters.next(Category.self)) { acronym, category in
            return acronym.categories.attach(category, on: req).transform(to: .created)
        }
    }

    func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        return try req.parameters.next(Acronym.self).flatMap(to: [Category].self) { acronym in
            try acronym.categories.query(on: req).all()
        }
    }
    
    func removeCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self, req.parameters.next(Acronym.self), req.parameters.next(Category.self)) { acronym, category in
            return acronym.categories.detach(category, on: req).transform(to: .noContent)
        }
    }
    
}
