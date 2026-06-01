package com.learning.rag_chatbot_app.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Component
public class QdrantClient {

    private final WebClient webClient;
    private final String collectionName = "my-docus";
    @Value("${qdrant.base-url}")
    private String baseUrl;

    public QdrantClient() {
        this.webClient = WebClient.builder()
                .baseUrl("http://localhost:6333")
                .defaultHeader("Content-Type", MediaType.APPLICATION_JSON_VALUE)
                .build();
        createCollectionIfNotExists();
    }

    public void createCollection() {
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
        Map<String, Object> body = Map.of("vector", vector, "top", 20,"with_payload",true);
        var response = webClient.post()
                .uri("/collections/" + collectionName + "/points/search")
                .bodyValue(body)
                .retrieve()
                .bodyToMono(Map.class)
                .block();


        List<String> matches = new ArrayList<>();

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
        return webClient.get()
                .uri("/collections")
                .retrieve()
                .bodyToMono(String.class)
                .block();
    }

    public void createCollectionIfNotExists(){
        String existing = listCollections();
        if (!existing.contains(collectionName)) {
            createCollection();
        }
    }

}