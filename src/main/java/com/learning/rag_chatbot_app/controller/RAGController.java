package com.learning.rag_chatbot_app.controller;


import com.learning.rag_chatbot_app.service.RAGService;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api")
public class RAGController {

    private final RAGService ragService;

    public RAGController(RAGService ragService) {
        this.ragService = ragService;
    }

    @PostMapping("/question")
    public ResponseEntity<String> askQuestion(@RequestParam String question) {
        return ResponseEntity.ok(ragService.answerQuestion(question));
    }

    @PostMapping(value = "/upload/files", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<String> uploadFiles(@RequestParam("files") List<MultipartFile> files) {
        try {
            ragService.uploadFiles(files);
            return ResponseEntity.ok("Files uploaded and processed successfully.");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Failed to upload files: " + e.getMessage());
        }
    }
    @GetMapping("/collections")
    public ResponseEntity<String> getCollections() {
        return ResponseEntity.ok(ragService.getCollections());
    }
}