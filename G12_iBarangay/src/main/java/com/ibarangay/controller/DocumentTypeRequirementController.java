package com.ibarangay.controller;

import com.ibarangay.dto.DocumentRequirementResponse;
import com.ibarangay.model.DocumentTypeRequirement;
import com.ibarangay.model.DocumentTypeRequirementId;
import com.ibarangay.service.DocumentTypeRequirementService;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/document-type-requirements")
public class DocumentTypeRequirementController {

    private final DocumentTypeRequirementService service;

    public DocumentTypeRequirementController(
            DocumentTypeRequirementService service) {
        this.service = service;
    }

    // Retrieve all document type requirements
    @GetMapping
    public List<DocumentTypeRequirement> getAll() {
        return service.getAllDocumentTypeRequirements();
    }

    // Retrieve requirements associated with a document type
    @GetMapping("/by-document-type/{documentTypeId}")
    public List<DocumentRequirementResponse> getRequirementsByDocumentTypeId(
            @PathVariable Long documentTypeId) {

        return service.getRequirementsByDocumentTypeId(documentTypeId);
    }

    // Retrieve a specific document type requirement
    @GetMapping("/{documentTypeId}/{requirementId}")
    public ResponseEntity<DocumentTypeRequirement> getById(
            @PathVariable Long documentTypeId,
            @PathVariable Long requirementId) {

        DocumentTypeRequirementId id =
                new DocumentTypeRequirementId(documentTypeId, requirementId);

        return service.getById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Create a document type requirement
    @PostMapping
    public ResponseEntity<DocumentTypeRequirement> create(
            @RequestBody DocumentTypeRequirement documentTypeRequirement) {

        DocumentTypeRequirement saved =
                service.save(documentTypeRequirement);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(saved);
    }

    // Update whether a requirement is mandatory or optional
    @PutMapping("/{documentTypeId}/{requirementId}")
    public ResponseEntity<DocumentTypeRequirement> update(
            @PathVariable Long documentTypeId,
            @PathVariable Long requirementId,
            @RequestBody DocumentTypeRequirement updatedRequirement) {

        DocumentTypeRequirementId id =
                new DocumentTypeRequirementId(documentTypeId, requirementId);

        return service.getById(id)
                .map(existing -> {

                    existing.setRequired(updatedRequirement.isRequired());

                    DocumentTypeRequirement saved =
                            service.save(existing);

                    return ResponseEntity.ok(saved);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    // Delete a document type requirement
    @DeleteMapping("/{documentTypeId}/{requirementId}")
    public ResponseEntity<Void> delete(
            @PathVariable Long documentTypeId,
            @PathVariable Long requirementId) {

        DocumentTypeRequirementId id =
                new DocumentTypeRequirementId(documentTypeId, requirementId);

        if (service.getById(id).isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        service.delete(id);

        return ResponseEntity.noContent().build();
    }
}