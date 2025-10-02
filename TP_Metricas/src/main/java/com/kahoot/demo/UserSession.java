package com.kahoot.demo;

import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import org.springframework.web.socket.WebSocketSession;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;


public class UserSession {
public final String name;
public final WebSocketSession ws;
public final BlockingQueue<Question> queue = new LinkedBlockingQueue<>();
public final AtomicInteger totalPoints = new AtomicInteger(0);
// store answers for current question id -> (selectedIndex, responseTimeMillis)
public final Map<Integer, AnswerRecord> answers = new ConcurrentHashMap<>();


public UserSession(String name, WebSocketSession ws){ this.name = name; this.ws = ws; }


public static class AnswerRecord {
public final int selectedIndex;
public final long responseMillis; // millis since question start
public AnswerRecord(int sel, long resp){ this.selectedIndex = sel; this.responseMillis = resp; }
}
}
