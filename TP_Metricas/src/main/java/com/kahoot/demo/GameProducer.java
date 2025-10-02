package com.kahoot.demo;

import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.List;
import java.util.Arrays;


public class GameProducer implements Runnable {
private final BlockingQueue<Question> out;
private final List<Question> questionBank;
public GameProducer(BlockingQueue<Question> out){
this.out = out;
this.questionBank = List.of(
new Question(1, "¿Capital de Francia?", List.of("Berlín","Madrid","París","Roma"), 2),
new Question(2, "2+2*2= ?", List.of("6","8","4","2"), 0),
new Question(3, "Color del cielo despejado?", List.of("Verde","Azul","Rojo","Amarillo"),1),
new Question(4, "Lenguaje principal de Android?", List.of("Swift","Kotlin","Python","C#"),1),
new Question(5, "Byte = ? bits", List.of("8","16","4","2"),0)
);
}
@Override
public void run(){
try{
for(Question q : questionBank){
out.put(q); // produce
// wait until dispatcher consumes and processes timing; small sleep
TimeUnit.MILLISECONDS.sleep(100);
}
}catch(InterruptedException e){ Thread.currentThread().interrupt(); }
}
}
