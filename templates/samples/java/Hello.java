import java.util.Scanner;
public class Hello {
    public static void main(String[] args) {
        Scanner s = new Scanner(System.in);
        String name = s.hasNextLine() ? s.nextLine() : "";
        System.out.println("hello, " + name);
    }
}
