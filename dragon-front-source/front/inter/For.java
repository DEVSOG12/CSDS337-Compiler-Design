package inter;
import lexer.*; import symbols.*;
public class For  extends Stmt {
    Expr expr; Stmt stmt1; Stmt stmt2; Stmt stmt3;

    public For() { expr = null; stmt1 = null; stmt2 = null; stmt3 = null; }

    public void init(Stmt s1, Expr x, Stmt s2, Stmt s3) {
        expr = x; stmt1 = s1; stmt2 = s2; stmt3 = s3;
        if( expr.type != Type.Bool ) expr.error("A Boolean required in for loop");
        // type of expr must be bool
    }

    public void gen(int b, int a) {
        after = a;
        int label1 = newlabel();
        stmt1.gen(b, label1);
        emitlabel(label1);
        expr.jumping(0, a);
        int label2 = newlabel();
        emitlabel(label2);
        int label3 = newlabel();
        stmt3.gen(label2, label3);
        emitlabel(label3);
        stmt2.gen(label3, a);
        emit("goto L" + label1);
    }
}
