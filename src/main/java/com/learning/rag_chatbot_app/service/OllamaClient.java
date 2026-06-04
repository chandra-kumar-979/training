package com.learning.rag_chatbot_app.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;

import jakarta.annotation.PostConstruct;
import java.util.List;
import java.util.Map;

@Component
public class OllamaClient {

    private WebClient webClient;

    @Value("${ollama.base-url:}")
    private String baseUrl;

    @Value("${ollama.embed.model:embed-model}")
    private String embedModel;

    @Value("${ollama.chat.model:chat-model}")
    private String chatModel;

    public OllamaClient() {
        // WebClient will be initialized in @PostConstruct using injected baseUrl
    }

    @PostConstruct
    public void init() {
        if (baseUrl == null || baseUrl.isBlank()) {
            System.err.println("Warning: 'ollama.base-url' is not configured. OllamaClient will be inactive.");
            return;
        }
        this.webClient = WebClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader("Content-Type", MediaType.APPLICATION_JSON_VALUE)
                .build();
    }

    public List<Float> getEmbedding(String text) {
        if (webClient == null) {
            throw new IllegalStateException("Ollama client not initialized (no base URL configured)");
        }
        Map<String, Object> body = Map.of("model", embedModel, "prompt", text);
        var response = webClient.post()
                .uri("/api/embeddings")
                .bodyValue(body)
                .retrieve()
                .bodyToMono(Map.class)
                .block();
        if (response == null) return null;
        return (List<Float>) response.get("embedding");
    }

    public Flux<String> generateAnswerStream(String question, List<String> context) {
        if (webClient == null) {
            return Flux.error(new IllegalStateException("Ollama client not initialized (no base URL configured)"));
        }

        String prompt = """
                   You are an expert assistant. Use the following information to answer the question precisely and concisely. If the answer is not contained in the content, respond with "The information is not available."
                   Please provide a clear, well-organized answer in complete sentences.

                   Content:
                   %s

                   Question:
                   %s

                   Answer:
                   """.formatted(String.join("\n", context), question);

        Map<String, Object> body = Map.of(
                "model", chatModel,
                "prompt", prompt,
                "stream", true   // Enable streaming output
        );

        return webClient.post()
                .uri("/api/generate")
                .bodyValue(body)
                .retrieve()
                .bodyToFlux(Map.class)
                .map(eventMap -> (String) eventMap.get("response"))
                .filter(chunk -> chunk != null && !chunk.isBlank());
    }
}