import Foundation

struct UserUpdated<C: UserContext> {
    let old: C
    let new: C
}
