package com.kahoot.demo;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import org.springframework.web.socket.TextMessage;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.stream.Collectors;

@Component
public class QuizEndpoint extends TextWebSocketHandler {
  private final GameManager gm = new GameManager();
  private final ObjectMapper mapper = new ObjectMapper();

  @Override
  public void afterConnectionEstablished(WebSocketSession session) throws Exception {
    // La conexión se establece, pero el usuario aún no está registrado
  }

  @Override
  protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
    Map payload = mapper.readValue(message.getPayload(), Map.class);
    String type = (String) payload.get("type");

    if ("join".equals(type)) {
      String name = (String) payload.get("name");
      if (gm.getSessions().size() >= GameManager.MAX_PLAYERS) {
        session.sendMessage(new TextMessage(mapper.writeValueAsString(
            Map.of("type", "joinFail", "reason", "Máximo de jugadores alcanzado"))));
        session.close();
        return;
      }
      UserSession us = new UserSession(name, session);
      gm.getSessions().put(name, us);
      session.sendMessage(new TextMessage(mapper.writeValueAsString(Map.of("type", "joined", "name", name))));

      if (gm.getSessions().size() == 1) {
        gm.startWithDelay(); // primera conexión activa temporizador
      }
      gm.startIfReady(); // si ya son 10 jugadores, comienza de inmediato
    }

    else if ("answer".equals(type)) {
      int qid = (int) payload.get("questionId");
      int sel = (int) payload.get("selectedIndex");
      String name = (String) payload.get("name");
      UserSession us = gm.getSessions().get(name);

      if (us != null) {
        // Calcular tiempo de respuesta desde el servidor
        long now = System.currentTimeMillis();
        long serverStart = payload.get("serverStart") != null
            ? ((Number) payload.get("serverStart")).longValue()
            : now;
        long responseMillis = now - serverStart;

        us.answers.put(qid, new UserSession.AnswerRecord(sel, responseMillis));
      }
    }

    else if ("finish".equals(type)) {
      // Cuando finalicen las preguntas, calcular podio y enviar a todos
      List<UserSession> top = gm.getSessions().values().stream()
          .sorted(Comparator.comparingInt((UserSession u) -> u.totalPoints.get()).reversed())
          .limit(3)
          .collect(Collectors.toList());

      List<Map<String, Object>> topList = new ArrayList<>();
    for (UserSession u : top) {
        Map<String, Object> map = new HashMap<>();
        map.put("name", u.name);
        map.put("points", u.totalPoints.get());
        topList.add(map);
    }


      String podiumMsg = mapper.writeValueAsString(Map.of("type", "podium", "top", topList));

      for (UserSession s : gm.getSessions().values()) {
        try {
          s.ws.sendMessage(new TextMessage(podiumMsg));
        } catch (Exception e) {
          e.printStackTrace();
        }
      }
    }
  }
}
