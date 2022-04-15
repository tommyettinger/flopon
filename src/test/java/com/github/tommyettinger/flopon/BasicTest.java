package com.github.tommyettinger.flopon;

import org.junit.Test;

public class BasicTest {
    public static class BasicHolder {
        public String name;
        public float f;
        public double d;
        public long l;
        public int i;
        public BasicHolder()
        {
            this("Jim");
        }
        public BasicHolder(String name) {
            this.name = name;
            d = (name.hashCode() * 0x9E3779B97F4A7C15L >> 12) * 0x1p-52;
            f = (name.hashCode() * 0x9E3779B9 >> 9) * 0x1p-23f;
            l = Double.doubleToLongBits(d) * 0x9E3779B9L;
            i = Float.floatToIntBits(f) * 0x9E37;
        }
    }
    @Test
    public void testWrite(){
        Flopon f = new Flopon(FloponWriter.OutputType.minimal);
        BasicHolder bill = new BasicHolder("Bill");
        String text = f.toFlopon(bill);
        System.out.println(text);
    }
    @Test
    public void testWriteRead(){
        Flopon f = new Flopon(FloponWriter.OutputType.minimal);
        BasicHolder bill = new BasicHolder("Bill");
        String text = f.toFlopon(bill);
        System.out.println(text);
        BasicHolder bill2 = f.fromFlopon(BasicHolder.class, text);
        System.out.println(bill2);
        System.out.println(f.toFlopon(bill2));
    }
}
