import Vapor

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        let usersRoute = router.grouped("api", "users")
        // Get all users.
        usersRoute.get(use: getAllHandler)
        // Add new user.
        usersRoute.post(User.self, use: createHandler)
        // Get user with ID equal to URL parameter.
        usersRoute.get(User.parameter, use: getHandler)
        // Get acronyms for user ID. (/api/user/<USER_ID>/acronyms).
        usersRoute.get(User.parameter, "acronyms", use: getAcronymsHandler)
    }
    
    func createHandler(_ req: Request, user: User) throws -> Future<User> {
        return user.save(on: req)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }
    
    func getHandler(_ req: Request) throws -> Future<User> {
        return try req.parameters.next(User.self)
    }
    
    // Get acronyms for user ID. (/api/user/<USER_ID>/acronyms).
    func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try req.parameters.next(User.self).flatMap(to: [Acronym].self) { user in
            try user.acronyms.query(on: req).all()
        }
    }
}
