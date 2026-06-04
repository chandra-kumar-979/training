package com.learning.rag_chatbot_app.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import jakarta.annotation.PostConstruct;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Component
public class QdrantClient {

    private WebClient webClient;
    private final String collectionName = "my-docus";
    @Value("${qdrant.base-url}")
    private String baseUrl;

    @PostConstruct
    public void init() {
        if (baseUrl == null || baseUrl.isBlank()) {
            System.err.println("Warning: 'qdrant.base-url' is not configured. QdrantClient will be inactive.");
            return;
        }

        try {
            this.webClient = WebClient.builder()
                    .baseUrl(baseUrl)
                    .defaultHeader("Content-Type", MediaType.APPLICATION_JSON_VALUE)
                    .build();
            try {
                createCollectionIfNotExists();
            } catch (Exception e) {
                // Do not fail application startup if Qdrant is not available yet; log and continue.
                System.err.println("Warning: failed to ensure Qdrant collection exists at startup: " + e.getMessage());
            }
        } catch (Exception e) {
            // Catch any exception from WebClient builder/init and avoid failing the bean creation
            System.err.println("Warning: failed to initialize WebClient for QdrantClient: " + e.getMessage());
            this.webClient = null;
        }
    }

    public void createCollection() {
        if (webClient == null) {
            System.err.println("createCollection skipped: Qdrant client not initialized.");
            return;
        }

        Map<String, Object> vectors = Map.of(
                "size", 768,
                "distance", "Cosine"
        );
        Map<String, Object> body = Map.of(
                "vectors", vectors
        );

        webClient.put()
                .uri("/collections/" + collectionName)
                .bodyValue(body)
                .retrieve()
                .toBodilessEntity()
                .block();
    }


    public void insertVector(UUID id, List<Float> vector, Map<String, Object> payload) {
        if (webClient == null) {
            System.err.println("insertVector skipped: Qdrant client not initialized.");
            return;
        }

        Map<String, Object> point = Map.of(
                "id", id.toString(),
                "vector", vector,
                "payload", payload
        );

        Map<String, Object> body = Map.of("points", List.of(point));

        webClient.put()
                .uri("/collections/" + collectionName + "/points")
                .bodyValue(body)
                .retrieve()
                .toBodilessEntity()
                .block();
    }


    public List<String> searchSimilarDocuments(List<Float> vector) {
        List<String> matches = new ArrayList<>();
        if (webClient == null) {
            System.err.println("searchSimilarDocuments: Qdrant client not initialized; returning empty results.");
            return matches;
        }

        Map<String, Object> body = Map.of("vector", vector, "top", 20, "with_payload", true);
        var response = webClient.post()
                .uri("/collections/" + collectionName + "/points/search")
                .bodyValue(body)
                .retrieve()
                .bodyToMono(Map.class)
                .block();

        if (response == null) {
            return matches;
        }

        Object resultsObj = response.get("result");
        if (!(resultsObj instanceof List<?> results)) {
            return matches;
        }

        for (Object item : results) {
            if (!(item instanceof Map<?, ?> resultItem)) continue;

            Object payloadObj = resultItem.get("payload");
            if (!(payloadObj instanceof Map<?, ?> payload)) continue;

            Object textObj = payload.get("text");
            if (textObj instanceof String) {
                matches.add((String) textObj);
            }
        }
        return matches;
    }


    public String listCollections() {
        if (webClient == null) {
            System.err.println("listCollections: Qdrant client not initialized; returning null.");
            return null;
        }
        return webClient.get()
                .uri("/collections")
                .retrieve()
                .bodyToMono(String.class)
                .block();
    }

    public void createCollectionIfNotExists(){
        String existing = listCollections();
        if (existing == null || !existing.contains(collectionName)) {
            createCollection();
        }
    }

}