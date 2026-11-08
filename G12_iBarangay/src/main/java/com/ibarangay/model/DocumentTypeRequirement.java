package com.ibarangay.model;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.MapsId;
import jakarta.persistence.Table;

@Entity
@Table(name = "document_type_requirements")
public class DocumentTypeRequirement {

    @EmbeddedId
    private DocumentTypeRequirementId id;

    @MapsId("documentTypeId")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "document_type_id", nullable = false)
    private DocumentType documentType;

    @MapsId("requirementId")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "requirement_id", nullable = false)
    private Requirement requirement;

    @Column(name = "is_required", nullable = false)
    private boolean required;

    // Getters and Setters

    public DocumentTypeRequirementId getId() {
        return id;
    }

    public void setId(DocumentTypeRequirementId id) {
        this.id = id;
    }

    public DocumentType getDocumentType() {
        return documentType;
    }

    public void setDocumentType(DocumentType documentType) {
        this.documentType = documentType;
    }

    public Requirement getRequirement() {
        return requirement;
    }

    public void setRequirement(Requirement requirement) {
        this.requirement = requirement;
    }

    public boolean isRequired() {
        return required;
    }

    public void setRequired(boolean required) {
        this.required = required;
    }
}