public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello, World from Docker Java!");
        System.out.println("Java version: " + System.getProperty("java.version"));
        System.out.println("Java runtime: " + System.getProperty("java.runtime.name"));
        System.out.println("OS: " + System.getProperty("os.name") + " " + System.getProperty("os.arch"));
    }
}
