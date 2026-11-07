package com.ibarangay.service;

import com.ibarangay.dto.DocumentTypeResponse;
import com.ibarangay.model.DocumentType;
import com.ibarangay.repository.DocumentTypeRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class DocumentTypeService {

    private final DocumentTypeRepository documentTypeRepository;

    public DocumentTypeService(DocumentTypeRepository documentTypeRepository) {
        this.documentTypeRepository = documentTypeRepository;
    }

    // Retrieve all document types
    public List<DocumentType> getAllDocumentTypes() {
        return documentTypeRepository.findAll();
    }

    // Retrieve all document types as DTO responses
    @Transactional(readOnly = true)
    public List<DocumentTypeResponse> getAllDocumentTypeResponses() {

        return documentTypeRepository.findAll()
                .stream()
                .map(this::convertToResponse)
                .toList();
    }

    // Retrieve only active document types for the citizen portal
    @Transactional(readOnly = true)
    public List<DocumentTypeResponse> getActiveDocumentTypes() {

        return documentTypeRepository.findAll()
                .stream()
                .filter(DocumentType::isActive)
                .map(this::convertToResponse)
                .toList();
    }

    // Retrieve document type by ID
    public Optional<DocumentType> getDocumentTypeById(Long documentTypeId) {
        return documentTypeRepository.findById(documentTypeId);
    }

    // Retrieve document type by ID as DTO
    @Transactional(readOnly = true)
    public Optional<DocumentTypeResponse> getDocumentTypeResponseById(
            Long documentTypeId) {

        return documentTypeRepository.findById(documentTypeId)
                .map(this::convertToResponse);
    }

    // Create or update document type
    public DocumentType saveDocumentType(DocumentType documentType) {
        return documentTypeRepository.save(documentType);
    }

    // Delete document type
    public void deleteDocumentType(Long documentTypeId) {
        documentTypeRepository.deleteById(documentTypeId);
    }

    // Check whether document type exists
    public boolean documentTypeExists(Long documentTypeId) {
        return documentTypeRepository.existsById(documentTypeId);
    }

    // Convert entity into DTO
    public DocumentTypeResponse convertToResponse(DocumentType documentType) {

        return new DocumentTypeResponse(
                documentType.getDocumentTypeId(),
                documentType.getName(),
                documentType.getDescription(),
                documentType.getProcessingDays(),
                documentType.getFee(),
                documentType.isActive()
        );
    }
}