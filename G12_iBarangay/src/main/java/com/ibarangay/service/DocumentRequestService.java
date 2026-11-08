package com.ibarangay.service;

import com.ibarangay.model.DocumentRequest;
import com.ibarangay.repository.DocumentRequestRepository;

import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class DocumentRequestService {

    private final DocumentRequestRepository documentRequestRepository;

    public DocumentRequestService(
            DocumentRequestRepository documentRequestRepository) {
        this.documentRequestRepository = documentRequestRepository;
    }

    // Retrieve all document requests
    public List<DocumentRequest> getAllDocumentRequests() {
        return documentRequestRepository.findAll();
    }

    // Retrieve document request by ID
    public Optional<DocumentRequest> getDocumentRequestById(Long requestId) {
        return documentRequestRepository.findById(requestId);
    }

    // Create or update document request
    public DocumentRequest saveDocumentRequest(DocumentRequest documentRequest) {
        return documentRequestRepository.save(documentRequest);
    }

    // Delete document request
    public void deleteDocumentRequest(Long requestId) {
        documentRequestRepository.deleteById(requestId);
    }

    // Check whether document request exists
    public boolean documentRequestExists(Long requestId) {
        return documentRequestRepository.existsById(requestId);
    }
}