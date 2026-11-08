package com.ibarangay.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "document_requests")
public class DocumentRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "request_id", nullable = false)
    private Long requestId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "citizen_id", nullable = false)
    private Citizen citizen;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "document_type_id", nullable = false)
    private DocumentType documentType;

    @Column(name = "request_date", nullable = false)
    private LocalDateTime requestDate;

    @Column(name = "purpose", nullable = false, length = 255)
    private String purpose;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "remarks", nullable = false, columnDefinition = "text")
    private String remarks;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approved_by")
    private Admin approvedBy;

    @Column(name = "processed_at")
    private LocalDateTime processedAt;

    @Column(name = "released_at")
    private LocalDateTime releasedAt;

    // Getters and Setters

    public Long getRequestId() {
        return requestId;
    }

    public void setRequestId(Long requestId) {
        this.requestId = requestId;
    }

    public Citizen getCitizen() {
        return citizen;
    }

    public void setCitizen(Citizen citizen) {
        this.citizen = citizen;
    }

    public DocumentType getDocumentType() {
        return documentType;
    }

    public void setDocumentType(DocumentType documentType) {
        this.documentType = documentType;
    }

    public LocalDateTime getRequestDate() {
        return requestDate;
    }

    public void setRequestDate(LocalDateTime requestDate) {
        this.requestDate = requestDate;
    }

    public String getPurpose() {
        return purpose;
    }

    public void setPurpose(String purpose) {
        this.purpose = purpose;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getRemarks() {
        return remarks;
    }

    public void setRemarks(String remarks) {
        this.remarks = remarks;
    }

    public Admin getApprovedBy() {
        return approvedBy;
    }

    public void setApprovedBy(Admin approvedBy) {
        this.approvedBy = approvedBy;
    }

    public LocalDateTime getProcessedAt() {
        return processedAt;
    }

    public void setProcessedAt(LocalDateTime processedAt) {
        this.processedAt = processedAt;
    }

    public LocalDateTime getReleasedAt() {
        return releasedAt;
    }

    public void setReleasedAt(LocalDateTime releasedAt) {
        this.releasedAt = releasedAt;
    }
}