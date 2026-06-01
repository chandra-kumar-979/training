package com.learning.rag_chatbot_app.service;

import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xslf.usermodel.XMLSlideShow;
import org.apache.poi.xslf.usermodel.XSLFShape;
import org.apache.poi.xslf.usermodel.XSLFSlide;
import org.apache.poi.xslf.usermodel.XSLFTextShape;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.apache.poi.xwpf.usermodel.XWPFParagraph;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.file.Files;

@Service
public class UniversalFileService {

    public String convertFileToString(File file) throws Exception {
        String extension = getExtension(file.getName()).toLowerCase();
        return switch (extension) {
            case "txt" -> readTextFile(file);
            case "pdf" -> readPdfFile(file);
            case "docx" -> readDocxFile(file);
            case "xlsx" -> readExcelFile(file);
            case "pptx" -> readPptxFile(file);
            case "json" -> readJsonFile(file);
            case "csv" -> readCsvFile(file);
            case "html" -> readHtmlFile(file);
            case "msg" -> readEmailFile(file);
            default -> throw new IllegalArgumentException("Unsupported file type");
        };
        }

        private String getExtension(String filename) {
            int dot = filename.lastIndexOf('.');
            return (dot == -1) ? "" : filename.substring(dot + 1);
        }

        public String readTextFile(File file) throws IOException {
            return Files.readString(file.toPath());
        }

        public String readPdfFile(File file) throws IOException {
            try (PDDocument document = PDDocument.load(file)) {
                return new PDFTextStripper().getText(document);
            }
        }

        public String readDocxFile(File file) throws IOException {
            try (FileInputStream fis = new FileInputStream(file);
                 XWPFDocument doc = new XWPFDocument(fis)) {
                StringBuilder sb = new StringBuilder();
                for (XWPFParagraph p : doc.getParagraphs()) {
                    sb.append(p.getText()).append('\n');
                }
                return sb.toString();
            }
        }

        public String readExcelFile(File file) throws Exception {
            try (FileInputStream fis = new FileInputStream(file);
                 Workbook workbook = WorkbookFactory.create(fis)) {
                StringBuilder sb = new StringBuilder();
                for (Sheet sheet : workbook) {
                    for (Row row : sheet) {
                        for (Cell cell : row) {
                            sb.append(cell.toString()).append('\t');
                        }
                        sb.append('\n');
                    }
                }
                return sb.toString();
            }
        }

        public String readPptxFile(File file) throws IOException {
            try (FileInputStream fis = new FileInputStream(file);
                 XMLSlideShow ppt = new XMLSlideShow(fis)) {
                StringBuilder sb = new StringBuilder();
                for (XSLFSlide slide : ppt.getSlides()) {
                    for (XSLFShape shape : slide.getShapes()) {
                        if (shape instanceof XSLFTextShape) {
                            sb.append(((XSLFTextShape) shape).getText()).append('\n');
                        }
                    }
                }
                return sb.toString();
            }
        }

    public String readJsonFile(File file) throws IOException {
        return Files.readString(file.toPath());
    }
    public String readCsvFile(File file) throws IOException {
        return Files.readString(file.toPath());
    }

    public String readHtmlFile(File file) throws IOException {
        return Files.readString(file.toPath());
    }

    public String readEmailFile(File file) throws Exception {
        Session session = Session.getDefaultInstance(System.getProperties());
        try (FileInputStream fis = new FileInputStream(file)) {
            MimeMessage message = new MimeMessage(session, fis);
            Object content = message.getContent();
            if (content instanceof String) {
                return (String) content;
            }
            return content.toString();
        }
    }


}
