package com.kahoot.demo;


import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;


@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {
private final QuizEndpoint quizEndpoint;
public WebSocketConfig(QuizEndpoint quizEndpoint){ this.quizEndpoint = quizEndpoint; }
@Override
public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
registry.addHandler(quizEndpoint, "/quiz").setAllowedOrigins("*");
}
}