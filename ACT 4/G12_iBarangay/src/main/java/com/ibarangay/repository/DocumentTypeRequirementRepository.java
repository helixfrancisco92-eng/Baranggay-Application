package com.ibarangay.repository;

import com.ibarangay.model.DocumentTypeRequirement;
import com.ibarangay.model.DocumentTypeRequirementId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DocumentTypeRequirementRepository
        extends JpaRepository<DocumentTypeRequirement, DocumentTypeRequirementId> {

    // Find all requirements associated with a document type
    List<DocumentTypeRequirement> findByDocumentType_DocumentTypeId(Long documentTypeId);

}