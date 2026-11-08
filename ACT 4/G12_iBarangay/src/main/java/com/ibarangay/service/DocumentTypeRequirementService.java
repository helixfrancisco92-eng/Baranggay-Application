package com.ibarangay.service;

import com.ibarangay.dto.DocumentRequirementResponse;
import com.ibarangay.model.DocumentTypeRequirement;
import com.ibarangay.model.DocumentTypeRequirementId;
import com.ibarangay.repository.DocumentTypeRequirementRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class DocumentTypeRequirementService {

    private final DocumentTypeRequirementRepository repository;

    public DocumentTypeRequirementService(
            DocumentTypeRequirementRepository repository) {
        this.repository = repository;
    }

    // Retrieve all document type requirements
    public List<DocumentTypeRequirement> getAllDocumentTypeRequirements() {
        return repository.findAll();
    }

    // Retrieve a record using its composite primary key
    public Optional<DocumentTypeRequirement> getById(
            DocumentTypeRequirementId id) {
        return repository.findById(id);
    }

    // Retrieve requirements for a specific document type as DTOs
    @Transactional(readOnly = true)
    public List<DocumentRequirementResponse> getRequirementsByDocumentTypeId(
            Long documentTypeId) {

        return repository.findByDocumentType_DocumentTypeId(documentTypeId)
                .stream()

                // Exclude inactive requirements
                .filter(record ->
                        record.getRequirement() != null
                                && record.getRequirement().isActive()
                )

                // Convert entity into DTO
                .map(record -> new DocumentRequirementResponse(
                        record.getRequirement().getRequirementId(),
                        record.getRequirement().getName(),
                        record.getRequirement().getDescription(),
                        record.isRequired()
                ))

                .toList();
    }

    // Create or update a document type requirement
    public DocumentTypeRequirement save(
            DocumentTypeRequirement documentTypeRequirement) {
        return repository.save(documentTypeRequirement);
    }

    // Delete a document type requirement
    public void delete(DocumentTypeRequirementId id) {
        repository.deleteById(id);
    }
}