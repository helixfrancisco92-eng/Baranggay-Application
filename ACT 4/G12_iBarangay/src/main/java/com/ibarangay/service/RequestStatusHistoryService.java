package com.ibarangay.service;

import com.ibarangay.model.RequestStatusHistory;
import com.ibarangay.repository.RequestStatusHistoryRepository;

import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class RequestStatusHistoryService {

    private final RequestStatusHistoryRepository historyRepository;

    public RequestStatusHistoryService(
            RequestStatusHistoryRepository historyRepository) {
        this.historyRepository = historyRepository;
    }

    // Retrieve all request status history records
    public List<RequestStatusHistory> getAllHistory() {
        return historyRepository.findAll();
    }

    // Retrieve history record by ID
    public Optional<RequestStatusHistory> getHistoryById(Long historyId) {
        return historyRepository.findById(historyId);
    }

    // Retrieve status history for a specific document request
    public List<RequestStatusHistory> getHistoryByRequestId(Long requestId) {
        return historyRepository
                .findByRequest_RequestIdOrderByChangedAtAsc(requestId);
    }

    // Create or update a status history record
    public RequestStatusHistory saveHistory(
            RequestStatusHistory history) {
        return historyRepository.save(history);
    }

    // Delete a status history record
    public void deleteHistory(Long historyId) {
        historyRepository.deleteById(historyId);
    }

    // Check whether a history record exists
    public boolean historyExists(Long historyId) {
        return historyRepository.existsById(historyId);
    }
}