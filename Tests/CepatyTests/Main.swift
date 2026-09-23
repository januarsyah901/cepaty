import Foundation

@main
struct TestMain {
    static func main() {
        let success = TestRunner.runAllTests()
        if !success {
            exit(1)
        }
    }
}
