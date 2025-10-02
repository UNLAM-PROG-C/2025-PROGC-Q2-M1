package com.kahoot.demo;


import java.util.List;
public class Question {
public final int id;
public final String text;
public final List<String> options; // size 4
public final int correctIndex; // 0..3
public Question(int id, String text, List<String> options, int correctIndex){
this.id = id; this.text = text; this.options = options; this.correctIndex = correctIndex;
}
}
