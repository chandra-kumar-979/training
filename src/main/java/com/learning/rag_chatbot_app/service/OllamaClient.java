package com.learning.rag_chatbot_app.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;

import java.util.List;
import java.util.Map;

@Component
public class OllamaClient {

    private final WebClient webClient;
    @Value("${ollama.base-url}")
    private String baseUrl;

    @Value("${ollama.embed.model}")
    private String embedModel;

    @Value("${ollama.chat.model}")
    private String chatModel;

    public OllamaClient() {
        this.webClient = WebClient.builder()
                .baseUrl("http://localhost:11434")
                .defaultHeader("Content-Type", MediaType.APPLICATION_JSON_VALUE)
                .build();
    }

    public List<Float> getEmbedding(String text) {
        Map<String, Object> body = Map.of("model", embedModel, "prompt", text);
        var response = webClient.post()
                .uri("/api/embeddings")
                .bodyValue(body)
                .retrieve()
                .bodyToMono(Map.class)
                .block();
        assert response != null;
        return (List<Float>) response.get("embedding");
    }

    public Flux<String> generateAnswerStream(String question, List<String> context) {
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