package com.learning.rag_chatbot_app.service;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class RAGService {

    private final QdrantClient qdrantClient;
    private final OllamaClient ollamaClient;
    private final UniversalFileService fileService;

    public RAGService(QdrantClient qdrantClient, OllamaClient ollamaClient, UniversalFileService fileService) {
        this.qdrantClient = qdrantClient;
        this.ollamaClient = ollamaClient;
        this.fileService = fileService;
    }

    public String answerQuestion(String question) {
        List<Float> questionEmbedding = ollamaClient.getEmbedding(question);
        List<String> contexts = qdrantClient.searchSimilarDocuments(questionEmbedding);

        return ollamaClient.generateAnswerStream(question, contexts)
                .collect(StringBuilder::new, StringBuilder::append)
                .map(StringBuilder::toString)
                .block();
    }

    public void uploadFiles(List<MultipartFile> files) {
        for (MultipartFile file : files) {
            try {
                String content = extractText(file);
                if (content == null || content.isEmpty()) {
                    throw new IllegalArgumentException("Extracted content is empty for file: " + file.getOriginalFilename());
                }

                List<String> chunks = splitIntoChunks(content);

                // Generate one unique document ID for all chunks of this document
                UUID documentId = UUID.randomUUID();

                for (int i = 0; i < chunks.size(); i++) {
                    String chunk = chunks.get(i);

                    List<Float> embedding = ollamaClient.getEmbedding(chunk);
                    if (embedding == null || embedding.size() != 768) {
                        throw new IllegalArgumentException("Embedding vector size mismatch for chunk in file: " + file.getOriginalFilename());
                    }

                    // Create unique point ID for each chunk
                    UUID chunkId = UUID.randomUUID();

                    // Include docId and chunkIndex in the payload for grouping
                    Map<String, Object> payload = Map.of(
                            "text", chunk,
                            "docId", documentId.toString(),
                            "chunkIndex", i
                    );

                    qdrantClient.insertVector(chunkId, embedding, payload);
                }
            } catch (Exception e) {
                throw new RuntimeException("Failed to process file: " + file.getOriginalFilename(), e);
            }
        }
    }

    private String extractText(MultipartFile file) throws Exception {

        File tempFile = File.createTempFile("upload", file.getOriginalFilename());
        file.transferTo(tempFile);
        return fileService.convertFileToString(tempFile);
    }

    private List<String> splitIntoChunks(String text) {
        int chunkSize = 768; // Adjust based on model limits
        List<String> chunks = new ArrayList<>();

        for (int i = 0; i < text.length(); i += chunkSize) {
            int end = Math.min(i + chunkSize, text.length());
            chunks.add(text.substring(i, end));
        }

        return chunks;
    }

    public String getCollections() {
        return qdrantClient.listCollections();
    }
}