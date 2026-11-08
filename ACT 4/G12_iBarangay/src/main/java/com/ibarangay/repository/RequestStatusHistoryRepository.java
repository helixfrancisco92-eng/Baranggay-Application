package com.ibarangay.repository;

import com.ibarangay.model.RequestStatusHistory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RequestStatusHistoryRepository
        extends JpaRepository<RequestStatusHistory, Long> {

    // Retrieve status history for a specific document request
    List<RequestStatusHistory> findByRequest_RequestIdOrderByChangedAtAsc(
            Long requestId
    );

}