package com.ibarangay.repository;

import com.ibarangay.model.DocumentRequest;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DocumentRequestRepository
        extends JpaRepository<DocumentRequest, Long> {

}