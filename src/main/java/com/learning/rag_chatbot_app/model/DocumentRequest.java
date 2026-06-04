package com.learning.rag_chatbot_app.model;

import org.springframework.web.multipart.MultipartFile;

import java.util.List;

public class DocumentRequest {
    private List<MultipartFile> multipartFiles;

    public DocumentRequest() {
    }

    public DocumentRequest(List<MultipartFile> multipartFiles) {
        this.multipartFiles = multipartFiles;
    }

    public List<MultipartFile> getMultipartFiles() {
        return multipartFiles;
    }

    public void setMultipartFiles(List<MultipartFile> multipartFiles) {
        this.multipartFiles = multipartFiles;
    }

    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private List<MultipartFile> multipartFiles;

        public Builder multipartFiles(List<MultipartFile> multipartFiles) {
            this.multipartFiles = multipartFiles;
            return this;
        }

        public DocumentRequest build() {
            return new DocumentRequest(multipartFiles);
        }
    }
}