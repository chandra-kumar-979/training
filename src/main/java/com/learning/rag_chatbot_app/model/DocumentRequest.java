package com.learning.rag_chatbot_app.model;

import lombok.Builder;
import lombok.Data;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@Data
@Builder
public class DocumentRequest {
    private List<MultipartFile> multipartFiles;
}