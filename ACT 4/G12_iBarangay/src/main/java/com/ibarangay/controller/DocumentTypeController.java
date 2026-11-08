package com.ibarangay.controller;

import com.ibarangay.dto.DocumentTypeResponse;
import com.ibarangay.model.DocumentType;
import com.ibarangay.service.DocumentTypeService;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/document-types")
public class DocumentTypeController {

    private final DocumentTypeService service;

    public DocumentTypeController(DocumentTypeService service) {
        this.service = service;
    }

    // Retrieve all document types
    @GetMapping
    public List<DocumentTypeResponse> getAll() {
        return service.getAllDocumentTypeResponses();
    }

    // Retrieve active document types
    @GetMapping("/active")
    public List<DocumentTypeResponse> getActive() {
        return service.getActiveDocumentTypes();
    }

    // Retrieve document type by ID
    @GetMapping("/{documentTypeId}")
    public ResponseEntity<DocumentTypeResponse> getById(
            @PathVariable Long documentTypeId) {

        return service.getDocumentTypeResponseById(documentTypeId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Create a new document type
    @PostMapping
    public ResponseEntity<DocumentTypeResponse> create(
            @RequestBody DocumentType documentType) {

        DocumentType saved = service.saveDocumentType(documentType);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(service.convertToResponse(saved));
    }

    // Update an existing document type
    @PutMapping("/{documentTypeId}")
    public ResponseEntity<DocumentTypeResponse> update(
            @PathVariable Long documentTypeId,
            @RequestBody DocumentType updatedDocumentType) {

        return service.getDocumentTypeById(documentTypeId)
                .map(existing -> {

                    existing.setName(updatedDocumentType.getName());
                    existing.setDescription(updatedDocumentType.getDescription());
                    existing.setProcessingDays(updatedDocumentType.getProcessingDays());
                    existing.setFee(updatedDocumentType.getFee());
                    existing.setActive(updatedDocumentType.isActive());

                    DocumentType saved =
                            service.saveDocumentType(existing);

                    return ResponseEntity.ok(
                            service.convertToResponse(saved)
                    );
                })
                .orElse(ResponseEntity.notFound().build());
    }

    // Delete a document type
    @DeleteMapping("/{documentTypeId}")
    public ResponseEntity<Void> delete(
            @PathVariable Long documentTypeId) {

        if (!service.documentTypeExists(documentTypeId)) {
            return ResponseEntity.notFound().build();
        }

        service.deleteDocumentType(documentTypeId);

        return ResponseEntity.noContent().build();
    }
}