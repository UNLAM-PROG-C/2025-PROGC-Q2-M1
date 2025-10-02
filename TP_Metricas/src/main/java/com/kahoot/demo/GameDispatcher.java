package com.kahoot.demo;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.web.socket.TextMessage;

import java.util.Map;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;

public class GameDispatcher implements Runnable {

    private final BlockingQueue<Question> in;
    private final Map<String, UserSession> sessions;
    private final ObjectMapper mapper = new ObjectMapper();
    public volatile boolean running = true;

    public GameDispatcher(BlockingQueue<Question> in, Map<String, UserSession> sessions) {
        this.in = in;
        this.sessions = sessions;
    }

    @Override
    public void run() {
        while (running) {
            try {
                Question q = in.take(); // consume produced question
                long questionStart = System.currentTimeMillis();

                // clear previous answers maps
                sessions.values().forEach(s -> s.answers.clear());

                // broadcast question
                String payload = mapper.writeValueAsString(Map.of(
                        "type", "question",
                        "id", q.id,
                        "text", q.text,
                        "options", q.options
                ));

                for (UserSession s : sessions.values()) {
                    try {
                        s.ws.sendMessage(new TextMessage(payload));
                    } catch (Exception ex) {
                        ex.printStackTrace();
                    }
                }

                // wait for 8 seconds collecting answers
                TimeUnit.SECONDS.sleep(8);

                // evaluate answers: award 10 for correct, then award fastest extra seconds
                long bestResp = Long.MAX_VALUE;
                boolean anyCorrect = false;

                for (UserSession s : sessions.values()) {
                    UserSession.AnswerRecord ar = s.answers.get(q.id);
                    if (ar != null && ar.selectedIndex == q.correctIndex) {
                        anyCorrect = true;
                        if (ar.responseMillis < bestResp) bestResp = ar.responseMillis;
                    }
                }

                // award points
                for (UserSession s : sessions.values()) {
                    UserSession.AnswerRecord ar = s.answers.get(q.id);
                    if (ar != null && ar.selectedIndex == q.correctIndex) {
                        int base = 10;
                        s.totalPoints.addAndGet(base);
                    }
                }

                // award bonus seconds to fastest correct (if any)
                if (anyCorrect) {
                    for (UserSession s : sessions.values()) {
                        UserSession.AnswerRecord ar = s.answers.get(q.id);
                        if (ar != null && ar.selectedIndex == q.correctIndex && ar.responseMillis == bestResp) {
                            int secondsUsed = (int) Math.ceil(ar.responseMillis / 1000.0);
                            int secondsLeft = Math.max(0, 8 - secondsUsed);
                            s.totalPoints.addAndGet(secondsLeft);
                        }
                    }
                }

                // send update with scores
                String scorePayload = mapper.writeValueAsString(Map.of(
                        "type", "scoreUpdate",
                        "scores", sessions.values().stream()
                                .map(ss -> Map.of("name", ss.name, "points", ss.totalPoints.get()))
                                .toArray()
                ));

                for (UserSession s : sessions.values()) {
                    try {
                        s.ws.sendMessage(new TextMessage(scorePayload));
                    } catch (Exception ex) {
                        ex.printStackTrace();
                    }
                }

            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        // ✅ Fin de juego: enviar podio
        try {
            var top = sessions.values().stream()
                    .sorted((a, b) -> b.totalPoints.get() - a.totalPoints.get())
                    .limit(3)
                    .map(u -> Map.of("name", u.name, "points", u.totalPoints.get()))
                    .toArray();

            String podiumPayload = mapper.writeValueAsString(Map.of("type", "podium", "top", top));

            for (UserSession s : sessions.values()) {
                try {
                    s.ws.sendMessage(new TextMessage(podiumPayload));
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
