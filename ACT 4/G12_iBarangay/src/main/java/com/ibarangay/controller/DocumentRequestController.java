package com.ibarangay.controller;

import com.ibarangay.model.DocumentRequest;
import com.ibarangay.service.DocumentRequestService;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/document-requests")
public class DocumentRequestController {

    private final DocumentRequestService service;

    public DocumentRequestController(DocumentRequestService service) {
        this.service = service;
    }

    // Retrieve all document requests
    @GetMapping
    public List<DocumentRequest> getAll() {
        return service.getAllDocumentRequests();
    }

    // Retrieve a document request by ID
    @GetMapping("/{requestId}")
    public ResponseEntity<DocumentRequest> getById(
            @PathVariable Long requestId) {

        return service.getDocumentRequestById(requestId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Create a new document request
    @PostMapping
    public ResponseEntity<DocumentRequest> create(
            @RequestBody DocumentRequest request) {

        if (request.getRequestDate() == null) {
            request.setRequestDate(LocalDateTime.now());
        }
        if (request.getStatus() == null || request.getStatus().trim().isEmpty()) {
            request.setStatus("PENDING");
        }

        DocumentRequest saved = service.saveDocumentRequest(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    // Update an existing document request
    @PutMapping("/{requestId}")
    public ResponseEntity<DocumentRequest> update(
            @PathVariable Long requestId,
            @RequestBody DocumentRequest updatedRequest) {

        return service.getDocumentRequestById(requestId)
                .map(existing -> {
                    if (updatedRequest.getStatus() != null) {
                        existing.setStatus(updatedRequest.getStatus());
                    }
                    if (updatedRequest.getRemarks() != null) {
                        existing.setRemarks(updatedRequest.getRemarks());
                    }
                    if (updatedRequest.getPurpose() != null) {
                        existing.setPurpose(updatedRequest.getPurpose());
                    }
                    if (updatedRequest.getProcessedAt() != null) {
                        existing.setProcessedAt(updatedRequest.getProcessedAt());
                    }
                    if (updatedRequest.getReleasedAt() != null) {
                        existing.setReleasedAt(updatedRequest.getReleasedAt());
                    }
                    if (updatedRequest.getApprovedBy() != null) {
                        existing.setApprovedBy(updatedRequest.getApprovedBy());
                    }

                    DocumentRequest saved = service.saveDocumentRequest(existing);
                    return ResponseEntity.ok(saved);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    // Delete a document request
    @DeleteMapping("/{requestId}")
    public ResponseEntity<Void> delete(
            @PathVariable Long requestId) {

        if (!service.documentRequestExists(requestId)) {
            return ResponseEntity.notFound().build();
        }

        service.deleteDocumentRequest(requestId);
        return ResponseEntity.noContent().build();
    }
}
