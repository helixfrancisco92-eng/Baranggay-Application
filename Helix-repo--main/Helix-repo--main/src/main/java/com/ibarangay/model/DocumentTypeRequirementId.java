package com.ibarangay.model;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class DocumentTypeRequirementId implements Serializable {

    @Column(name = "document_type_id", nullable = false)
    private Long documentTypeId;

    @Column(name = "requirement_id", nullable = false)
    private Long requirementId;

    public DocumentTypeRequirementId() {
    }

    public DocumentTypeRequirementId(Long documentTypeId, Long requirementId) {
        this.documentTypeId = documentTypeId;
        this.requirementId = requirementId;
    }

    public Long getDocumentTypeId() {
        return documentTypeId;
    }

    public void setDocumentTypeId(Long documentTypeId) {
        this.documentTypeId = documentTypeId;
    }

    public Long getRequirementId() {
        return requirementId;
    }

    public void setRequirementId(Long requirementId) {
        this.requirementId = requirementId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof DocumentTypeRequirementId)) return false;

        DocumentTypeRequirementId that = (DocumentTypeRequirementId) o;

        return Objects.equals(documentTypeId, that.documentTypeId)
                && Objects.equals(requirementId, that.requirementId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(documentTypeId, requirementId);
    }
}