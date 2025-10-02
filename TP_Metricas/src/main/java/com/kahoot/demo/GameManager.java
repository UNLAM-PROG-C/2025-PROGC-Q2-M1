package com.kahoot.demo;

import java.util.Map;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicBoolean;

public class GameManager {
    public static final int MAX_PLAYERS = 10;
    public static final int WAIT_TIME_SECONDS = 30; // si no llegan 10, esperar 30s

    private final BlockingQueue<Question> producerQueue = new LinkedBlockingQueue<>();
    private final Map<String, UserSession> sessions = new ConcurrentHashMap<>();

    private final GameProducer producer = new GameProducer(producerQueue);
    private final GameDispatcher dispatcher = new GameDispatcher(producerQueue, sessions);

    private final ScheduledExecutorService sched = Executors.newScheduledThreadPool(2);
    private final AtomicBoolean started = new AtomicBoolean(false);

    // ✅ acceso a las sesiones desde otros componentes
    public Map<String, UserSession> getSessions() {
        return sessions;
    }

    // ✅ Inicia el juego inmediatamente si llegan 10 jugadores
    public void startIfReady() {
        if (sessions.size() >= MAX_PLAYERS && started.compareAndSet(false, true)) {
            startGame();
        }
    }

    // ✅ Inicia el juego tras X segundos aunque no se llegue a 10 jugadores
    public void startWithDelay() {
        sched.schedule(() -> {
            if (started.compareAndSet(false, true)) {
                startGame();
            }
        }, WAIT_TIME_SECONDS, TimeUnit.SECONDS);
    }

    // ✅ Inicio real del juego
    private void startGame() {
        System.out.println("🎮 El juego comienza con " + sessions.size() + " jugadores.");

        // Hilo productor → genera 5 preguntas
        sched.execute(producer);

        // Hilo consumidor/dispatcher → reparte preguntas y calcula podio
        sched.execute(dispatcher);
    }

    // ✅ Detener recursos al final
    public void shutdown() {
        sched.shutdown();
        try {
            if (!sched.awaitTermination(5, TimeUnit.SECONDS)) {
                sched.shutdownNow();
            }
        } catch (InterruptedException e) {
            sched.shutdownNow();
        }
    }
}
