import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "acronyms")
        
        // Get all acronyms.
        acronymsRoutes.get(use: getAllHandler)
        // Add new acronym.
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
    
    func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).sort(\.short, .ascending).all()
    }

}
