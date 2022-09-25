@main
public struct SlideUI {
    public private(set) var text = "Hello, World!"

    public static func main() {
        print(SlideUI().text)
    }
}
